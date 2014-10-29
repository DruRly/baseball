require 'smarter_csv'

class Player
  attr_accessor :player_id, :league, :at_bats, :hits, :doubles, :triples, :home_runs, :rbi, :year, :team

  BATTING_FILE = "./data/Batting-07-12.csv"

  class << self
    def all
      players ||=
        SmarterCSV.process(BATTING_FILE, {row_sep: "\r"}).map do |player|
        csv_record_to_object player
        end
    end

    def find id, players
      players.find { |player| player.player_id == id }
    end

    def csv_record_to_object player
      Player.new({
        player_id: player[:playerid],
        at_bats:   player[:ab],
        hits:      player[:h],
        doubles:   player[:"2b"],
        triples:   player[:"3b"],
        home_runs: player[:hr],
        rbi:       player[:rbi],
        league:    player[:league],
        team:      player[:teamid],
        year:      player[:yearid]
      })
    end
  end

  def initialize(options = {})
    @player_id = options[:player_id]
    @at_bats   = options[:at_bats]
    @hits      = options[:hits]
    @doubles   = options[:doubles]
    @triples   = options[:triples]
    @home_runs = options[:home_runs]
    @rbi       = options[:rbi]
    @league    = options[:league]
    @team      = options[:team]
    @year      = options[:year]
  end

  def slugging_percentage
    if can_calculate_slugging_percentage?
      ((hits - doubles - triples - home_runs) + (2 * doubles) + (3 * triples) + (4 * home_runs)) / at_bats.to_f
    end
  end

  def batting_average
    if can_calculate_batting_average?
      (hits / at_bats.to_f)
    end
  end

  def eligible_for_triple_crown?
    at_bats && at_bats >= 400
  end

  def played_in_year? year
    self.year == year
  end

  def played_in_league? league
    self.league == league
  end

  def played_on_team? team
    self.team == team
  end

  private

  def can_calculate_slugging_percentage?
    [hits, doubles, triples, home_runs, at_bats].all? { |attr| !attr.nil? } && at_bats.nonzero?
  end

  def can_calculate_batting_average?
    [hits, at_bats].all? { |attr| !attr.nil? } && at_bats.nonzero?
  end
end

module BaseballStatsCalculator
  class << self
    def average_slugging_percentage team, year
      players_of_interest = players_by_year(year)
      players_of_interest = players_by_team(team, players_of_interest)

      slugging_percentages = players_of_interest.map(&:slugging_percentage).compact
      (slugging_percentages.reduce(:+).to_f / slugging_percentages.size).round(3)
    end

    def most_improved_batting_average year_from, year_to
      first_year_players                = players_by_year(year_from)
      second_year_players               = players_by_year(year_to)
      players_who_played_both_years_ids = played_both_years(first_year_players, second_year_players)
      player_average_differences        = batting_average_differences(players_who_played_both_years_ids,
                                                                      first_year_players,
                                                                      second_year_players)
      player_average_differences.compact.sort_by{ |hash| hash[:difference] }.last
    end

    def batting_average_differences ids, year_from_players, year_to_players
      batting_average_differences = ids.map do |playerid|
        from_record          = Player.find playerid, year_from_players
        to_record            = Player.find playerid, year_to_players
        records_are_eligible = records_eligible_for_most_improved?(from_record, to_record)
        batting_average_difference_for_player(playerid, from_record, to_record) if records_are_eligible
      end
    end

    def batting_average_difference_for_player playerid, from_record, to_record
      previous_batting_average = from_record.batting_average
      latest_batting_average   = to_record.batting_average
      difference               = (latest_batting_average - previous_batting_average).round(3)
      { playerid: playerid, difference: difference }
    end

    def played_both_years players_from, players_to
      players_from.map(&:player_id) & players_to.map(&:player_id)
    end

    def triple_crown_winner year
      triple_crown_winners = []
      players_of_interest = players_by_year year
      eligible_players    = players_eligible_for_triple_crown players_of_interest
      player_leagues      = eligible_players.map { |player| player.league }.uniq

      player_leagues.map do |league_name|
        winner = triple_crown_league_winner eligible_players, league_name
        triple_crown_winners << winner if winner
      end
      triple_crown_winners.empty? ? "(No winner)" : triple_crown_winners
    end

    def triple_crown_league_winner players, league
      league_players          = players_by_league(league, players)
      highest_batting_average = highest_batting_average(league_players)
      most_home_runs          = most_home_runs(league_players)
      most_rbi                = most_rbi(league_players)
      records                 = [highest_batting_average, most_home_runs, most_rbi]
      records.uniq.length == 1 ? records.first : nil
    end

    def players_eligible_for_triple_crown players
      players.select { |player| player.eligible_for_triple_crown? }
    end

    def highest_batting_average players
      players.sort_by(&:batting_average).last.player_id
    end

    def most_home_runs players
      players.sort_by(&:home_runs).last.player_id
    end

    def most_rbi players
      players.sort_by(&:rbi).last.player_id
    end

    def records_eligible_for_most_improved? from_record, to_record
      ((from_record.at_bats >= 200) && (to_record.at_bats >= 200))
    end

    private

    def players_by_team team, players=Player.all
      players.select { |player| player.played_on_team? team }
    end

    def players_by_year year, players=Player.all
      players.select { |player| player.played_in_year? year }
    end

    def players_by_league league, players=Player.all
      players.select { |player| player.played_in_league? league }
    end
  end
end
