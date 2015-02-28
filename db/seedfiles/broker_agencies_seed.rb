puts "*"*80
puts "::: Cleaning Broker Agencies:::"
BrokerAgency.delete_all

puts "::: Generating Broker Agencies:::"

p0 = Person.where(last_name: "Murray").first
p1 = Person.where(last_name: "Chase").first
p3 = Person.where(last_name: "Curtin").first
bk1 = BrokerRole.find_by_npn("2068981")
bk0 = BrokerRole.find_by_npn("1682443")

# BrokerAgency.create!(name: "ACME Agency", primary_broker: bk0, broker_agency_contacts: [p0], market_kind: "both")
BrokerAgency.create!(name: "ACME Agency", primary_broker: bk0, market_kind: "both")

# BrokerAgency.create!(name: "Chase & Assoc", primary_broker: bk1, broker_agency_contacts: [p1, p3], market_kind: "both")
BrokerAgency.create!(name: "Chase & Assoc", primary_broker: bk1, broker_agency_contacts: [p1, p3], market_kind: "both")

puts "::: Broker Agencies Complete :::"
puts "*"*80
