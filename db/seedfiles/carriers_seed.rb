puts "*"*80
puts "::: Generating MA Carriers:::"

hbx_office = OfficeLocation.new(
    is_primary: true,
    address: {kind: "work", address_1: "address_placeholder", address_2: "address_2", city: "City", state: "St", zip: "10001" },
    phone: {kind: "main", area_code: "111", number: "111-1111"}
  )

org = Organization.new(fein: "043373331", legal_name: "Boston Medical Center HealthNet Plan", office_locations: [hbx_office])
cp = org.create_carrier_profile(id: "53e67210eb899a4603000029", abbrev: "BMCHP", hbx_carrier_id: 20003, ivl_health: false, ivl_dental: false, shop_health: true, shop_dental: true, issuer_hios_ids: ['82569'], offers_sole_source: true)

org = Organization.new(fein: "237442369", legal_name: "Fallon Community Health Plan", office_locations: [hbx_office])
cp = org.create_carrier_profile(id: "53e67210eb899a4603000037", abbrev: "FCHP", hbx_carrier_id: 20005, ivl_health: false, ivl_dental: false, shop_health: true, shop_dental: true, issuer_hios_ids: ['88806'], offers_sole_source: true)

org = Organization.new(fein: "042864973", legal_name: "Health New England", office_locations: [hbx_office])
cp = org.create_carrier_profile(id: "53e67210eb899a4603000045", abbrev: "HNE", hbx_carrier_id: 20007, ivl_health: false, ivl_dental: false, shop_health: true, shop_dental: true, issuer_hios_ids: ['34484'])

puts "::: Generated MA Carriers :::"
puts "*"*80
