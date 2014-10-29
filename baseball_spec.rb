require 'rspec'
require 'factory_girl'
require_relative 'baseball'

RSpec.configure do |config|
  config.include FactoryGirl::Syntax::Methods
end

FactoryGirl.define do
  factory :player do
    player_id "player01"
    at_bats 200
    hits 60
    doubles 8
    triples 4
    home_runs 3
    rbi 10
    league "NL"
    team "OAK"
    year 2008

    initialize_with { new({
      player_id: player_id,
      at_bats: at_bats,
      hits: hits,
      year: year,
      league: league,
      doubles: doubles,
      triples: triples,
      home_runs: home_runs,
      team: team,
      rbi: rbi
    }) }
  end
end

describe Player do
  let(:player) { FactoryGirl.build(:player, player_id: 'jane', league: 'NL', year: 2009) }
  subject { player }

  describe "::all" do
    it 'returns a non-empty result' do
      expect(Player.all).not_to be_empty
    end
  end

  describe "#slugging_percentage" do
    context 'able to calculate' do

      it 'returns the slugging percentage' do
        expect(subject.slugging_percentage).to eq(0.425)
      end
    end

    context 'unable to calculate' do
      before { player.doubles = nil }

      it 'returns nil' do
        expect(subject.slugging_percentage).to be_nil
      end
    end
  end

  describe "#batting_average" do
    context 'able to calculate' do
      before do
        player.hits    = 10
        player.at_bats = 40
      end

      it 'returns the batting average ' do
        expect(subject.batting_average).to eq(0.25)
      end
    end

    context 'unable to calculate' do
      before { player.hits = nil }

      it 'returns nil' do
        expect(subject.batting_average).to be_nil
      end
    end
  end

  describe "#eligible_for_triple_crown?" do
    context 'eligible' do
      before { player.at_bats = 401 }

      it 'returns true' do
        expect(subject.eligible_for_triple_crown?).to eq(true)
      end
    end

    context 'ineligible' do
      before { player.at_bats = 399 }

      it 'returns false' do
        expect(subject.eligible_for_triple_crown?).to eq(false)
      end
    end
  end
end

describe BaseballStatsCalculator do
  subject { described_class }

  let(:league) { "NL" }

  let(:jane_2009_season) { FactoryGirl.build(:player, player_id: 'jane', team: 'OAK', league: league, year: 2009)          }
  let(:jane_2010_season) { FactoryGirl.build(:player, player_id: 'jane', team: 'OAK', league: league, year: 2010)          }
  let(:joe_2009_season)  { FactoryGirl.build(:player, player_id: 'joe', team: 'OAK', league: league, year: 2009)           }
  let(:joe_2010_season)  { FactoryGirl.build(:player, player_id: 'joe', team: 'OAK', league: league, hits: 68, year: 2010) }
  let(:sam_2009_season)  { FactoryGirl.build(:player, player_id: 'sam', league: league, year: 2009)                        }
  let(:players)          { [ jane_2009_season, jane_2010_season, joe_2009_season, joe_2010_season, sam_2009_season] }


  before { allow(Player).to receive(:all).and_return(players) }

  describe "::average_slugging_percentage" do
    let(:team)   { "OAK" }
    let(:year)   { 2010  }

    it 'returns the slugging percentage for a player' do
      expect(subject.average_slugging_percentage(team, year)).to eq(0.445)
    end
  end

  describe "::most_home_runs" do
    before { joe_2010_season.home_runs = 50 }

    it 'returns the player with the most home runs' do
      expect(subject.most_home_runs(players)).to eq('joe')
    end
  end


  describe "::most_rbi" do
    before { sam_2009_season.rbi = 80 }

    it 'returns the player with the most home runs' do
      expect(subject.most_rbi(players)).to eq('sam')
    end
  end

  describe "::played_both_years" do
    let(:players_from)   { [ jane_2009_season, joe_2009_season, sam_2009_season ]}
    let(:players_to)     { [ jane_2010_season, joe_2010_season ]}
    let(:common_players) { ['jane', 'joe'] }

    it 'returns players from two hashes that played both years' do
      expect(subject.played_both_years(players_from, players_to)).to eq(common_players)
    end
  end

  describe "::triple_crown_winner" do
    context 'there is a triple crown winner' do
      before do
        jane_2010_season.hits      = 150
        jane_2010_season.at_bats   = 401
        jane_2010_season.home_runs = 80
        jane_2010_season.rbi       = 125
      end

      it 'returns the triple crown winner(s) for a given year' do
        expect(subject.triple_crown_winner(2010)).to eq(['jane'])
      end
    end

    context 'there is no triple crown winner' do
      let(:losers) {[ joe_2010_season, jane_2010_season ]}

      it 'returns the triple crown winner(s) for a given year' do
        expect(subject.triple_crown_winner(2010)).to eq("(No winner)")
      end
    end
  end

  context 'batting average calculations' do
    let(:batting_average_difference) { { playerid: "joe", difference: 0.04 } }

    describe "::most_improved_batting_average" do
      it 'returns the most improved player based on batting average' do
        expect(subject.most_improved_batting_average(2009, 2010)).to eq(batting_average_difference)
      end
    end

    describe "::batting_average_difference" do
      let(:from_record) { joe_2009_season }
      let(:to_record)   { joe_2010_season }
      let(:playerid)    { batting_average_difference[:playerid] }

      it 'returns the difference in batting average for a given player' do
        expect(subject.batting_average_difference_for_player(playerid, from_record, to_record)).to eq(batting_average_difference)
      end
    end

    describe "::highest_batting_average" do
      before do
        jane_2010_season.hits    = 150
        jane_2010_season.at_bats = 200
      end

      it 'returns the player with the highest batting average' do
        expect(subject.highest_batting_average(players)).to eq('jane')
      end
    end
  end
end
