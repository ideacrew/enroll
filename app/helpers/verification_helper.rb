module VerificationHelper

  def admin_docs_filter(filter_param, title = nil, style = nil)
    direction = filter_param == sort_filter && sort_direction == 'asc' ? 'desc' : 'asc'
    style = direction if style == 'admin_docs'
    link_to title, consumer_role_status_documents_path(:sort => filter_param, :direction => direction), remote: true, class: style
  end

  def docs_waiting_for_review
    Person.unverified_persons.in('consumer_role.vlp_documents.status':['downloaded', 'in review']).count
  end

  def missing_docs
    Person.unverified_persons.where('consumer_role.vlp_documents.status': 'not submitted').count
  end

  def all_unverified
    number_with_delimiter(@unverified_persons.count)
  end

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
      when "in review"
        "info"
      when "verified"
        "success"
      else
        "danger"
    end
  end

  def verification_type_status(type)
    case type
      when 'SSN'
        @person.consumer_role.is_state_resident? ? "verified" : "outstanding"
      when 'Citizenship'
        @person.consumer_role.is_state_resident? ? "verified" : "outstanding"
      when 'Immigration status'
        @person.consumer_role.lawful_presence_authorized? ? "verified" : "outstanding"
    end
  end

  def verification_type_class(type)
    verification_type_status(type) == "verified" ? "success" : "danger"
  end

  def unverified?(person)
    true if person.consumer_role.aasm_state != "fully_verified"
  end

  def enrollment_group_verified?(person)
    person.primary_family.active_family_members.all? {|member| member.person.consumer_role.aasm_state == "fully_verified"}
  end

  def coverage_household_verification
    "???????"
  end

  def verification_due_date
    @person.consumer_role.lawful_presence_determination.latest_denial_date.try(:+, 90.days).try(:>, TimeKeeper.date_of_record) || (TimeKeeper.date_of_record + 90.days)
  end
end