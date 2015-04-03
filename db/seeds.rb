# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

puts "Start of seed data"
puts "*"*80

puts "::: Purging Database :::"
system "rake db:purge"
# puts "::: Cleaning Broker Agencies:::"
# Organization.delete_all
# puts "::: Cleaning People :::"
# Person.delete_all
# puts "::: Cleaning Plans :::"
# Plan.delete_all

# require File.join(File.dirname(__FILE__),'seedfiles', 'carriers')
# require File.join(File.dirname(__FILE__),'seedfiles', 'premiums')
require File.join(File.dirname(__FILE__),'seedfiles', 'people_seed')
require File.join(File.dirname(__FILE__),'seedfiles', 'broker_agencies_seed')
require File.join(File.dirname(__FILE__),'seedfiles', 'employers_seed')
require File.join(File.dirname(__FILE__),'seedfiles', 'carriers_seed')
require File.join(File.dirname(__FILE__),'seedfiles', 'employees_seed')

# puts "*"*80
# puts "::: Generating Plans:::"
# system "rake seed:plans"
# require File.join(File.dirname(__FILE__),'seedfiles', 'plan_benefits_seed')

system "rake seed:plans"
system "rake hbx:employers:add[tmp/employer_export.csv,tmp/users_to_ignore.csv]"
system "rake hbx:employers:census:add[tmp/census.csv]"

puts "*"*80
puts "End of Seed Data"