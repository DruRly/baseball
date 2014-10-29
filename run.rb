require_relative 'baseball'

#1. Most improved batting average
year_from = 2009
year_to = 2010
puts "Most improved batting average (#{year_from} to #{year_to})"
puts BaseballStatsCalculator.most_improved_batting_average year_from, year_to

#2. Slugging percentage
team = "OAK"
year = 2007
puts "Slugging percentage for #{team} during #{year}"
puts BaseballStatsCalculator.average_slugging_percentage "OAK", 2007

#3. Triple crown winner
crown_years = [2011, 2012]
crown_years.each do |year|
  puts "Triple crown winner for #{year}"
  puts BaseballStatsCalculator.triple_crown_winner year
end
