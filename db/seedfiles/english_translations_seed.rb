puts "*"*80
puts "::: Generating English Translations :::"

Translation.find_or_initialize_by(key: "en.header.call_customer_service", value: '"Call Customer Service"').save
Translation.find_or_initialize_by(key: "en.header.help", value: '"Help"').save
Translation.find_or_initialize_by(key: "en.header.logout", value: '"Logout"').save
Translation.find_or_initialize_by(key: "en.header.my_id", value: '"My ID"').save
Translation.find_or_initialize_by(key: "en.header.my_insured_portal", value: '"My Insured Portal"').save
Translation.find_or_initialize_by(key: "en.sign_in.create_account", value: '"Create Customer Account"').save
Translation.find_or_initialize_by(key: "en.wecome.sign_out", value: '"Sign Out"').save
Translation.find_or_initialize_by(key: "en.welcome.assisted_consumer_family_portal", value: '"Assisted Consumer/Family Portal"').save
Translation.find_or_initialize_by(key: "en.welcome.broker_agency_portal", value: '"Broker Agency Portal"').save
Translation.find_or_initialize_by(key: "en.welcome.broker_registration", value: '"Broker Registration"').save
Translation.find_or_initialize_by(key: "en.welcome.byline", value: '"The Right Place for the Right Plan"').save
Translation.find_or_initialize_by(key: "en.welcome.consumer_family_portal", value: '"Consumer/Family Portal"').save
Translation.find_or_initialize_by(key: "en.welcome.employee_portal", value: '"Employee Portal"').save
Translation.find_or_initialize_by(key: "en.welcome.employer_portal", value: '"Employer Portal"').save
Translation.find_or_initialize_by(key: "en.welcome.general_agency_portal", value: '"General Agency Portal"').save
Translation.find_or_initialize_by(key: "en.welcome.general_agency_registration", value: '"General Agency Registration"').save
Translation.find_or_initialize_by(key: "en.welcome.hbx_portal", value: '"HBX Portal"').save
Translation.find_or_initialize_by(key: "en.welcome.logout", value: '"Logout"').save
Translation.find_or_initialize_by(key: "en.welcome.returning_user", value: '"Returning User"').save
Translation.find_or_initialize_by(key: "en.welcome.signed_in_as", value: '"Signed in as %{current_user}"').save
Translation.find_or_initialize_by(key: "en.welcome.welcome_email", value: '"Welcome %{current_user}"').save
Translation.find_or_initialize_by(key: "en.welcome.welcome_to_site_name", value: '"Welcome to %{short_name}"').save

puts "::: English Translations Complete :::"
puts "*"*80
