module VerificationHelper

  # info popover list of the documents types that consumer can upload as vlp_document
  def info_pop_up(type)
    case type
      when 'SSN'
        VlpDocument::SSN_DOCUMENTS_KINDS.join('; ')
      when 'Citizenship'
        VlpDocument::CITIZENSHIP_DOCUMENTS_KINDS.join('; ')
      when 'Immigration status'
        VlpDocument::VLP_DOCUMENT_KINDS.join('; ')
    end
  end

  def doc_status_label(doc)
    case doc.status
      when "not submitted"
        "warning"
      when "downloaded"
        "default"
      when "verified"
        "success"
      else
        "danger"
    end
  end

  def verification_type_status(type)
     if type == 'SSN' || type == 'Citizenship'
        @person.consumer_role.is_state_resident? ? "verified" : "outstanding"
     elsif type == 'Immigration status'
        @person.consumer_role.lawful_presence_authorized? ? "verified" : "outstanding"
     end
  end

  def verification_type_class(type)
    verification_type_status(type) == "verified" ? "success" : "danger"
  end

  def unverified?(person)
    person.consumer_role.aasm_state != "fully_verified"
  end

  def enrollment_group_verified?(person)
    person.primary_family.active_family_members.all? {|member| member.person.consumer_role.aasm_state == "fully_verified"} if person.has_consumer_role?
  end

  def verification_due_date(person)
    if person.consumer_role.special_verification_period
      person.consumer_role.special_verification_period.strftime("%m/%d/%Y")
    else
      person.consumer_role.lawful_presence_determination.latest_denial_date.try(:+, 90.days).try(:>, TimeKeeper.date_of_record) || (TimeKeeper.date_of_record + 90.days)
    end
  end

  def documents_uploaded(person)
    person.primary_family.active_family_members.any? { |member| member_has_uploaded_docs(member) }
  end

  def member_has_uploaded_docs(member)
    true if member.person.consumer_role.try(:vlp_documents).any? { |doc| doc.identifier }
  end

  def documents_count(person)
    person.consumer_role.vlp_documents.select{|doc| doc.identifier}.count
  end

  def review_button_class(family)
    if family.active_household.hbx_enrollments.first.review_status == "ready"
      "success"
    elsif family.active_household.hbx_enrollments.first.review_status == "in review"
      "info"
    else
      "default"
    end
  end

  def fedhub_responce(member)
    if member.person.try(:consumer_role).try(:lawful_presence_determination).try(:latest_denial_date)
      "FedHub fail"
    end
  end

  def show_send_button_for_consumer?(person)
    current_user.has_consumer_role? && hbx_enrollment_incomplete && documents_uploaded(person)
  end

  def hbx_enrollment_incomplete
    @person.primary_family.active_household.hbx_enrollments.empty? || @person.primary_family.try(:active_household).try(:hbx_enrollments).try(:first).try(:review_status) == "incomplete"
  end
end