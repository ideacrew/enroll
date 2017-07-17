module VerificationHelper

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

  def verification_type_status(type, member)
    case type
      when 'Social Security Number'
        if member.consumer_role.ssn_verified?
          "verified"
        elsif member.consumer_role.has_docs_for_type?(type)
          "in review"
        else
          "outstanding"
        end
      when 'American Indian Status'
        if member.consumer_role.native_verified?
          "verified"
        elsif member.consumer_role.has_docs_for_type?(type)
          "in review"
        else
          "outstanding"
        end
      else
        if member.consumer_role.lawful_presence_verified?
          "verified"
        elsif member.consumer_role.has_docs_for_type?(type)
          "in review"
        else
          "outstanding"
        end
    end
  end

  def verification_type_class(type, member)
    case verification_type_status(type, member)
      when "verified"
        "success"
      when "in review"
        "warning"
      when "outstanding"
        member.consumer_role.processing_hub_24h? ? "info" : "danger"
    end
  end

  def unverified?(person)
    person.consumer_role.aasm_state != "fully_verified"
  end

  def enrollment_group_unverified?(person)
    person.primary_family.active_family_members.any? {|member| member.person.consumer_role.aasm_state == "verification_outstanding"}
  end

  def verification_needed?(person)
    person.primary_family.active_household.hbx_enrollments.verification_needed.any? if person.try(:primary_family).try(:active_household).try(:hbx_enrollments)
  end

  def documents_uploaded
    @person.primary_family.active_family_members.all? { |member| docs_uploaded_for_all_types(member) }
  end

  def member_has_uploaded_docs(member)
    true if member.person.consumer_role.try(:vlp_documents).any? { |doc| doc.identifier }
  end

  def member_has_uploaded_paper_applications(member)
    true if member.person.resident_role.try(:paper_applications).any? { |doc| doc.identifier }
  end

  def docs_uploaded_for_all_types(member)
    member.person.verification_types.all? do |type|
      member.person.consumer_role.vlp_documents.any?{ |doc| doc.identifier && doc.verification_type == type }
    end
  end

  def documents_count(person)
    return 0 unless person.consumer_role
    person.consumer_role.vlp_documents.select{|doc| doc.identifier}.count
  end

  def review_button_class(family)
    if family.active_household.hbx_enrollments.verification_needed.any?
      if family.active_household.hbx_enrollments.verification_needed.first.review_status == "ready"
        "success"
      elsif family.active_household.hbx_enrollments.verification_needed.first.review_status == "in review"
        "info"
      else
        "default"
      end
    end
  end

  def show_send_button_for_consumer?
    current_user.has_consumer_role? && hbx_enrollment_incomplete && documents_uploaded
  end

  def hbx_enrollment_incomplete
    if @person.primary_family.active_household.hbx_enrollments.verification_needed.any?
      @person.primary_family.active_household.hbx_enrollments.verification_needed.first.review_status == "incomplete"
    end
  end

  #use this method to send docs to review for family member level
  def all_docs_rejected(person)
    person.try(:consumer_role).try(:vlp_documents).select{|doc| doc.identifier}.all?{|doc| doc.status == "rejected"}
  end

  def no_enrollments
    @person.primary_family.active_household.hbx_enrollments.empty?
  end

  def enrollment_incomplete
    if @person.primary_family.active_household.hbx_enrollments.verification_needed.any?
      @person.primary_family.active_household.hbx_enrollments.verification_needed.first.review_status == "incomplete"
    end
  end

  def all_family_members_verified
    @family_members.all?{|member| member.person.consumer_role.aasm_state == "fully_verified"}
  end

  def show_doc_status(status)
    ["verified", "rejected"].include?(status)
  end

  def show_v_type(v_type, person)
    case verification_type_status(v_type, person)
      when "in review"
        "&nbsp;&nbsp;&nbsp;In Review&nbsp;&nbsp;&nbsp;".html_safe
      when "verified"
        "&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Verified&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;".html_safe
      else
        person.consumer_role.processing_hub_24h? ? "&nbsp;&nbsp;Processing&nbsp;&nbsp;".html_safe : "Outstanding"
    end
  end

  def text_center(v_type, person)
    (current_user && !current_user.has_hbx_staff_role?) || show_v_type(v_type, person) == '&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Verified&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;'
  end

  # returns vlp_documents array for verification type
  def documents_list(person, v_type)
    person.consumer_role.vlp_documents.select{|doc| doc.identifier && doc.verification_type == v_type } if person.consumer_role
  end

  def admin_actions(v_type, f_member)
    options_for_select(build_admin_actions_list(v_type, f_member))
  end

  def build_admin_actions_list(v_type, f_member)
    if verification_type_status(v_type, f_member) == "outstanding"
      ::VlpDocument::ADMIN_VERIFICATION_ACTIONS.reject{|el| el == "Reject"}
    else
      ::VlpDocument::ADMIN_VERIFICATION_ACTIONS
    end
  end

  def build_reject_reason_list(v_type)
    case v_type
      when "Citizenship"
        ::VlpDocument::CITIZEN_IMMIGR_TYPE_ADD_REASONS + ::VlpDocument::ALL_TYPES_REJECT_REASONS
      when "Immigration status"
        ::VlpDocument::CITIZEN_IMMIGR_TYPE_ADD_REASONS + ::VlpDocument::ALL_TYPES_REJECT_REASONS
      when "Income" #will be implemented later
        ::VlpDocument::INCOME_TYPE_ADD_REASONS + ::VlpDocument::ALL_TYPES_REJECT_REASONS
      else
        ::VlpDocument::ALL_TYPES_REJECT_REASONS
    end
  end

  def type_unverified?(v_type, person)
    verification_type_status(v_type, person) != "verified"
  end
end
