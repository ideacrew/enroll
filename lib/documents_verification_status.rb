module DocumentsVerificationStatus   
    def verification_type_status(type, member, admin=false)
    consumer = member.consumer_role
    return "curam" if (consumer.vlp_authority == "curam" && consumer.fully_verified? && admin)
    return 'attested' if (type == 'DC Residency' && member.age_on(TimeKeeper.date_of_record) <= 18)
    case type
      when 'Social Security Number'
        if consumer.ssn_verified?
          "verified"
        elsif consumer.has_docs_for_type?(type) && !consumer.ssn_rejected
          "in review"
        else
          "outstanding"
        end
      when 'American Indian Status'
        if consumer.native_verified?
          "verified"
        elsif consumer.has_docs_for_type?(type) && !consumer.native_rejected
          "in review"
        else
          "outstanding"
        end
      when 'DC Residency'
        if consumer.residency_verified?
          consumer.local_residency_validation
        elsif consumer.has_docs_for_type?(type) && !consumer.residency_rejected
          "in review"
        else
          "outstanding"
        end
      else
        if consumer.lawful_presence_verified?
          "verified"
        elsif consumer.has_docs_for_type?(type) && !consumer.lawful_presence_rejected
          "in review"
        else
          "outstanding"
        end
    end
  end
end