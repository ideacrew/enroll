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
     if type == 'Social Security Number' || type == 'Citizenship'
        member.consumer_role.is_state_resident? ? "verified" : "outstanding"
     elsif type == 'Immigration status'
        member.consumer_role.lawful_presence_authorized? ? "verified" : "outstanding"
     end
  end

  def verification_type_class(type, member)
    verification_type_status(type, member) == "verified" ? "success" : "danger"
  end

  def unverified?(person)
    person.consumer_role.aasm_state != "fully_verified"
  end

  def enrollment_group_verified?(person)
    person.primary_family.active_family_members.all? {|member| member.person.consumer_role.aasm_state == "fully_verified"} if person.has_consumer_role?
  end

  def enrollment_due_date?(person)
    person.primary_family.active_household.hbx_enrollments.verification_needed.any?
  end

  def verification_due_date(family)
    if family.try(:active_household).try(:hbx_enrollments).try(:verification_needed).try(:any?)
      if family.active_household.hbx_enrollments.verification_needed.first.special_verification_period
        family.active_household.hbx_enrollments.verification_needed.first.special_verification_period.to_date
      else
        family.active_household.hbx_enrollments.verification_needed.first.updated_at.to_date + 95.days
      end
    else
      TimeKeeper.date_of_record.to_date + 95.days
    end
  end

  def documents_uploaded
    @person.primary_family.active_family_members.all? { |member| docs_uploaded_for_all_types(member) }
  end

  def member_has_uploaded_docs(member)
    true if member.person.consumer_role.try(:vlp_documents).any? { |doc| doc.identifier }
  end

  def docs_uploaded_for_all_types(member)
    member.person.verification_types.all? do |type|
      member.person.consumer_role.vlp_documents.any?{ |doc| doc.identifier && doc.verification_type == type }
    end
  end

  def documents_count(person)
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
    no_enrollments || enrollment_incomplete
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
end