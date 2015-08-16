# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

reset_tasks = %w(
  db:mongoid:purge
  db:mongoid:remove_indexes
  db:mongoid:create_indexes
)
puts "*"*80
puts "Purging Database"
system "rake #{reset_tasks.join(" ")}"
puts "*"*80

puts "*"*80
puts "Start of seed data"
puts "*"*80


puts "*"*80
puts "Loading carriers and QLE kinds."
require File.join(File.dirname(__FILE__),'seedfiles', 'carriers_seed')
require File.join(File.dirname(__FILE__),'seedfiles', 'qualifying_life_event_kinds_seed')

load_tasks = %w(
  seed:plans
  seed:people
  seed:families
  hbx:employers:add[db/seedfiles/employers.csv,db/seedfiles/blacklist.csv]
  hbx:employers:census:add[db/seedfiles/census.csv]
)
puts "*"*80
puts "Loading sanitized plans, people, families, employers, and census."
system "rake #{load_tasks.join(" ")}"
puts "*"*80

# require File.join(File.dirname(__FILE__),'seedfiles', 'premiums')

puts "*"*80
puts "Loading constructed geographic areas, people, broker agencies, employers, and employees."
require File.join(File.dirname(__FILE__),'seedfiles', 'us_counties_seed')
require File.join(File.dirname(__FILE__),'seedfiles', 'admins_seed')
require File.join(File.dirname(__FILE__),'seedfiles', 'people_seed')
require File.join(File.dirname(__FILE__),'seedfiles', 'broker_agencies_seed')
require File.join(File.dirname(__FILE__),'seedfiles', 'employers_seed')
require File.join(File.dirname(__FILE__),'seedfiles', 'employees_seed')
require File.join(File.dirname(__FILE__),'seedfiles', 'slcsp_seed')

puts "*"*80

puts "*"*80
puts "Loading SERFF data"

Products::Qhp.delete_all
files = Dir.glob(File.join(Rails.root, "db/seedfiles/plan_xmls", "**", "*.xml"))
qhp_import_hash = files.inject(QhpBuilder.new({})) do |qhp_hash, file|
  puts file
  xml = Nokogiri::XML(File.open(file))
  plan = Parser::PlanBenefitTemplateParser.parse(xml.root.canonicalize, :single => true)
  qhp_hash.add(plan.to_hash)
  qhp_hash
end

qhp_import_hash.run
puts "*"*80

require File.join(File.dirname(__FILE__),'seedfiles', 'shop_2015_sbc_files')

puts "*"*80
puts "End of Seed Data"
