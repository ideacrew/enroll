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
  def info_pop_up
    VlpDocument::VLP_DOCUMENT_KINDS.join('; ')
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

  def verification_type

  end

  def verification_type_class
    "danger"
  end

  def unverified?(member)
    true if member.person.consumer_role.aasm_state != "fully_verified"
  end
end