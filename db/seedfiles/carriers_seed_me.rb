puts "*"*80
puts "::: Generating ME Carriers:::"

hbx_office = OfficeLocation.new(
    is_primary: true,
    address: {kind: "work", address_1: "address_placeholder", address_2: "address_2", city: "City", state: "St", zip: "10001" },
    phone: {kind: "main", area_code: "111", number: "111-1111"}
  )

org = Organization.new(fein: "453416923", legal_name: "Community Health Options", office_locations: [hbx_office])
cp = org.create_carrier_profile(id: "53e67210eb899a4603000045", abbrev: "CHO", hbx_carrier_id: 30_001, ivl_health: true, ivl_dental: true, shop_health: false, shop_dental: false, issuer_hios_ids: ['33653'])

org = Organization.new(fein: "042452600", legal_name: "Harvard Pilgrim Health Care", office_locations: [hbx_office])
cp = org.create_carrier_profile(id: "53e67210eb899a4603000029", abbrev: "HPHC", hbx_carrier_id: 30_002, ivl_health: true, ivl_dental: true, shop_health: false, shop_dental: false, issuer_hios_ids: ['96667'])

org = Organization.new(fein: "311705652", legal_name: "Anthem Blue Cross and Blue Shield", office_locations: [hbx_office])
cp = org.create_carrier_profile(id: "53e67210eb899a4603000037", abbrev: "ANTHM", hbx_carrier_id: 30_004, ivl_health: true, ivl_dental: true, shop_health: false, shop_dental: false, issuer_hios_ids: ['48396'])

org = Organization.new(fein: "010286541", legal_name: "Northeast Delta Dental", office_locations: [hbx_office])
cp = org.create_carrier_profile(id: "53e67210eb899a4603000073", abbrev: "NEDD", hbx_carrier_id: 30_005, ivl_health: true, ivl_dental: true, shop_health: false, shop_dental: false, issuer_hios_ids: ['50165'])

org = Organization.new(fein: "873357382", legal_name: "Taro Health Plan of State, Inc.", office_locations: [hbx_office])
cp = org.create_carrier_profile(id: "53e67210eb899a4603000077", abbrev: "TARO", hbx_carrier_id: 30_006, ivl_health: true, ivl_dental: true, shop_health: false, shop_dental: false, issuer_hios_ids: ['54879'])

puts "::: Generated ME Carriers :::"
puts "*"*80
