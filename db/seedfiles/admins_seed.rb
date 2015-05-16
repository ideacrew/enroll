puts "*"*80
puts "::: Creating HBX Admin:::"


address  = Address.new(kind: "work", address_1: "609 H St", city: "Washington", state: "DC", zip: "20002")
phone    = Phone.new(kind: "main", area_code: "202", number: "555-9999")
email    = Email.new(kind: "work", address: "info@hbx.gov")
office_location= OfficeLocation.new(is_primary: true, address: address, phone: phone, email: email)

hbx = Organization.create(
      dba: "DCHL",
      legal_name: "DC HealthLinke",
      fein: 444123456,
      office_locations: [office_location]
    )

hbx.build_hbx_profile(cms_id: "DC0")

admin_user    = User.create!(email: "admin@dc.gov", password: "password", password_confirmation: "password", roles: ["hbx_staff"])
admin_person  = Person.new(first_name: "system", last_name: "admin", user: admin_user)
admin_person.build_hbx_staff_role(hbx_profile_id: hbx._id, job_title: "grand poobah", department: "accountability")
admin_person.save!

puts "::: HBX Admins Complete :::"
