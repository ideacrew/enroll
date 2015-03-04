puts "*"*80
puts "::: Cleaning Broker Agencies:::"
Organization.delete_all

puts "::: Generating Broker Agencies:::"

p0 = Person.where(last_name: "Murray").first
p1 = Person.where(last_name: "Chase").first
p3 = Person.where(last_name: "Curtin").first
bk1 = BrokerRole.find_by_npn("2068981")
bk0 = BrokerRole.find_by_npn("1682443")

office0 = OfficeLocation.new(address: {kind: "work", address_1: "101 Main St", city: "Washington", state: "DC", zip: "20001"}, phone: {kind: "work", area_code: "202", number: "555-1212"})
org0 = Organization.new(legal_name: "ACME Agency", fein: "034267010", office_locations: [office0])
org0.create_broker_agency_profile(primary_broker: bk0, market_kind: "both")

office1 = OfficeLocation.new(address: {kind: "work", address_1: "102 Main St", city: "Washington", state: "DC", zip: "20001"}, phone: {kind: "work", area_code: "202", number: "555-1213"})
org1 = Organization.new(legal_name: "Chase & Assoc", fein: "034267001", office_locations: [office1])
org1.create_broker_agency_profile(primary_broker: bk1, broker_agency_contacts: [p1, p3], market_kind: "both")

puts "::: Broker Agencies Complete :::"
puts "*"*80
