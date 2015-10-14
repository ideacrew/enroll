broker_people = People.where({"broker_role._id" => {"$exists" => true}})

CSV.open("invited_brokers.csv", "o") do |csv|
  csv << [
    "Broker",
    "NPN",
    "Email",
    "Invitation URL",
    "Invitation ID"
  ]
  broker_people.each do |bp|
    invitation = Invitation.invite_broker!(bp.broker_profile)
    csv << [
      bp.full_name,
      bp.broker_profile.npn,
      invitation.invitation_email,
      "https://enroll.dchealthlink.com/invitations/claim/#{invitation.id.to_s}",
      invitation.invitation_id.to_s
    ]
  end
end
