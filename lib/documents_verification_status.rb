module DocumentsVerificationStatus
  def verification_type_status(type, member, admin=false)
    consumer = member.consumer_role
    if (consumer.vlp_authority == "curam" && consumer.fully_verified?)
      admin ? "curam" : "External source"
    else
      type.validation_status
    end
  end
end