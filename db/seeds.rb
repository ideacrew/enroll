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

# require File.join(File.dirname(__FILE__),'seedfiles', 'carriers')
# require File.join(File.dirname(__FILE__),'seedfiles', 'premiums')
system "rake seed:plans"
require File.join(File.dirname(__FILE__),'seedfiles', 'people_seed')
require File.join(File.dirname(__FILE__),'seedfiles', 'broker_agencies_seed')
require File.join(File.dirname(__FILE__),'seedfiles', 'employers_seed')
require File.join(File.dirname(__FILE__),'seedfiles', 'carriers_seed')
require File.join(File.dirname(__FILE__),'seedfiles', 'employees_seed')
require File.join(File.dirname(__FILE__),'seedfiles', 'qualifying_life_event_kinds_seed')

system "seed:people seed:families"
system "rake hbx:employers:add[tmp/employer_export.csv,tmp/users_to_ignore.csv]"
system "rake hbx:employers:census:add[tmp/census.csv]"

# Products::Qhp.delete_all

# rake xml:plans['tmp/AE_DC_IVL_77422_Benefits__v1.xml']
# rake xml:plans['tmp/AE_DC_SG_73987_Benefits_ON_v2.xml']
# rake xml:plans['tmp/AE_DC_SG_77422_Benefits_ON_v1.xml']
# rake xml:plans['tmp/HIX_DC_Individual_78079_GHMSI_v1.xml']
# rake xml:plans['tmp/HIX_DC_Individual_86052_CFBC_v1.xml']
# rake xml:plans['tmp/HIX_DC_Small Group_78079_GHMSI_v1.xml']
# rake xml:plans['tmp/HIX_DC_Small Group_86052_CFBC_v1.xml']
# rake xml:plans['tmp/KP DC Individual Plan and Benefits Template_9-18-2014.xml']
# rake xml:plans['tmp/KP DC SHOP Plan and Benefit Template_09182014.xml']
# rake xml:plans['tmp/dc_21066_uhcma_shop_pbt_10232014_final_marketingnameupdates.xml']
# rake xml:plans['tmp/dc_41842_uhic_shop_both_pbt_10232014_marketingnameupdates.xml']
# rake xml:plans['tmp/dc_75753_on_shop_oci_pbt_planreview_mktname_10232014_final.xml']




puts "*"*80
puts "End of Seed Data"