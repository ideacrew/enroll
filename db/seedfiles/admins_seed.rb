puts "*"*80
puts "::: Creating HBX Admin:::"

admin_user    = User.create!(email: "admin@dc.gov", password: "password", password_confirmation: "password", roles: ["hbx_staff"])
admin_person  = Person.new(first_name: "system", last_name: "admin", user: admin_user)
admin_person.build_hbx_staff_role(job_title: "grand poobah", department: "accountability")
admin_person.save!

puts "::: HBX Admins Complete :::"
