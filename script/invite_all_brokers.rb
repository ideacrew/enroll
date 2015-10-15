broker_people = Person.where({"broker_role._id" => {"$exists" => true}})

CSV.open("invited_brokers.csv", "w") do |csv|
  csv << [
    "Broker",
    "NPN",
    "Email",
    "Invitation URL",
    "Invitation ID"
  ]
  broker_people.each do |bp|
    broker_role = bp.broker_role
    invitation = Invitation.create(
      :role => "broker_agency_staff_role",
      :source_kind => "broker_agency_staff_role",
      :source_id => broker_role.id,
      :invitation_email => broker_role.email_address
    )
    csv << [
      bp.full_name,
      broker_role.npn,
      invitation.invitation_email,
      "https://enroll.dchealthlink.com/invitations/claim/#{invitation.id.to_s}",
      invitation.id.to_s
    ]
  end
end
