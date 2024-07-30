# frozen_string_literal: true

module VerificationHelper
  include DocumentsVerificationStatus
  include HtmlScrubberUtil

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

  def ridp_type_status(type, person)
    consumer = person.consumer_role
    case type
    when 'Identity'
      if consumer.identity_verified? || consumer.identity_rejected
        consumer.identity_validation
      elsif consumer.has_ridp_docs_for_type?(type) && !consumer.identity_rejected
        'in review'
      else
        'outstanding'
      end
    when 'Application'
      if consumer.application_verified? || consumer.application_rejected
        consumer.application_validation
      elsif consumer.has_ridp_docs_for_type?(type) && !consumer.application_rejected
        'in review'
      else
        'outstanding'
      end
    end
  end

  def display_verification_type_name(v_type)
    case v_type
    when 'ME Residency'
      'Income'
    when 'Alive Status'
      'Deceased'
    else
      v_type
    end
  end

  def verification_type_class(status)
    case status
    when 'verified', 'valid'
      'success'
    when 'review', 'negative_response_received'
      'warning'
    when 'outstanding', 'rejected'
      'danger'
    when 'curam', 'attested', 'expired', 'unverified'
      'default'
    when 'pending'
      'info'
    end
  end

  def ridp_type_class(type, person)
    case ridp_type_status(type, person)
    when 'valid'
      'success'
    when 'in review'
      'warning'
    when 'outstanding', 'rejected'
      'danger'
    end
  end

  def unverified?(person)
    person.consumer_role.aasm_state != "fully_verified"
  end

  def enrollment_group_unverified?(person)
    is_unverified_verification_type?(person) || is_unverified_evidences?(person) || is_family_has_unverified_verifications?(person)
  end

  def is_family_has_unverified_verifications?(person)
    return false unless EnrollRegistry.feature_enabled?(:include_faa_outstanding_verifications)
    return false if person.primary_family.enrollments.enrolled_and_renewal.blank?
    ed = person.primary_family.eligibility_determination
    return false unless ed.present?
    return false unless ed.outstanding_verification_status == 'outstanding'
    !ed.outstanding_verification_earliest_due_date.nil? && ed.outstanding_verification_document_status != 'Fully Uploaded'
  end

  def is_unverified_verification_type?(person)
    person.primary_family.contingent_enrolled_active_family_members.flat_map(&:person).flat_map(&:consumer_role).flat_map(&:verification_types).select{|type| type.is_type_outstanding?}.any?
  end

  def is_unverified_evidences?(person)
    return false if person.primary_family.enrollments.enrolled_and_renewal.blank?
    application = FinancialAssistance::Application.where(family_id: person.primary_family.id).determined.order_by(:created_at => 'desc').first
    aasm_states = []
    application&.active_applicants&.each do |applicant|
      next unless applicant.is_applying_coverage
      FinancialAssistance::Applicant::EVIDENCES.each do |evidence_type|
        next if evidence_type == :income_evidence && applicant.incomes.blank?
        evidence = applicant.send(evidence_type)
        aasm_states << evidence.aasm_state if evidence.present?
      end
    end

    (Eligibilities::Evidence::OUTSTANDING_STATES & aasm_states).any?
  end

  def verification_needed?(person)
    person.primary_family.active_household.hbx_enrollments.verification_needed.any? if person.try(:primary_family).try(:active_household).try(:hbx_enrollments)
  end

  def has_enrolled_policy?(family_member)
    return true if family_member.blank?
    family_member.family.enrolled_policy(family_member).present?
  end

  def is_not_verified?(family_member, v_type)
    return true if family_member.blank?
    !(["na", "verified", "attested", "expired"].include?(v_type.validation_status))
  end

  def can_show_due_date?(person)
    ed = person.primary_family&.eligibility_determination
    ed&.outstanding_verification_earliest_due_date.present? || ed&.outstanding_verification_status&.to_s == 'outstanding'
  end

  def default_verification_due_date
    verification_document_due = EnrollRegistry[:verification_document_due_in_days].item
    TimeKeeper.date_of_record + verification_document_due.days
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

  def documents_count(family)
    family.family_members.map(&:person).flat_map(&:consumer_role).flat_map(&:vlp_documents).select{|doc| doc.identifier}.count
  end

  def get_person_v_type_status(people)
    v_type_status_list = []
    people.each do |person|
      person.verification_types.without_alive_status_type.each do |v_type|
        v_type_status_list << verification_type_status(v_type, person)
      end
    end
    v_type_status_list
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

  def show_v_type(status, admin = nil)
    if status == "curam"
      admin ? "External Source".center(12) : sanitize_html("verified".capitalize.center(12).gsub(' ', '&nbsp;'))
    elsif status
      status = "verified" if status == "valid"
      status = l10n('verification_type.validation_status') if status == 'rejected'
      sanitize_html(status.titleize.center(12).gsub(' ', '&nbsp;'))
    end
  end

  def show_ridp_type(ridp_type, person)
    case ridp_type_status(ridp_type, person)
    when 'in review'
      sanitize_html("&nbsp;&nbsp;&nbsp;In Review&nbsp;&nbsp;&nbsp;")
    when 'valid'
      sanitize_html("&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Verified&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;")
    when 'rejected'
      l10n('verification_type.validation_status')
    else
      sanitize_html("&nbsp;&nbsp;Outstanding&nbsp;&nbsp;")
    end
  end

  # returns vlp_documents array for verification type
  def documents_list(person, v_type)
    person.consumer_role.vlp_documents.select{|doc| doc.identifier && doc.verification_type == v_type } if person.consumer_role
  end

  # returns ridp_documents array for ridp verification type
  def ridp_documents_list(person, ridp_type)
    person.consumer_role.ridp_documents.select{|doc| doc.identifier && doc.ridp_verification_type == ridp_type } if person.consumer_role
  end

  def admin_actions(v_type, f_member)
    options_for_select(build_admin_actions_list(v_type, f_member))
  end

  def display_upload_for_verification?(verification_type)
    verification_type.type_unverified?
  end

  def mod_attr(attr, val)
      attr.to_s + " => " + val.to_s
  end

  def ridp_admin_actions(ridp_type, person)
    options_for_select(build_ridp_admin_actions_list(ridp_type, person))
  end

  def build_admin_actions_list(v_type, f_member)
    rejected_list = EnrollRegistry.feature_enabled?(:enable_call_hub_for_ai_an) ? ['Alive Status', 'American Indian Status'] : ['Alive Status']
    if f_member.consumer_role.aasm_state == 'unverified' || rejected_list.include?(v_type.type_name)
      ::VlpDocument::ADMIN_VERIFICATION_ACTIONS.reject{ |el| el == 'Call HUB' }
    elsif verification_type_status(v_type, f_member) == 'outstanding'
      ::VlpDocument::ADMIN_VERIFICATION_ACTIONS.reject{|el| el == "Reject" }
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

  def build_ridp_admin_actions_list(ridp_type, person)
    if ridp_type_status(ridp_type, person) == 'outstanding'
      ::RidpDocument::ADMIN_VERIFICATION_ACTIONS.reject{|el| el == 'Reject'}
    else
      ::RidpDocument::ADMIN_VERIFICATION_ACTIONS
    end
  end

  def type_unverified?(v_type, person)
    !["verified", "valid", "attested"].include?(verification_type_status(v_type, person))
  end

  def request_response_details(person, record, v_type)
    return show_deceased_verification_response(person, record) if v_type == "Alive Status"

    local_residency = EnrollRegistry[:enroll_app].setting(:state_residency).item
    if record.event_request_record_id
      v_type == local_residency ? show_residency_request(person, record) : show_ssa_dhs_request(person, record)
    elsif record.event_response_record_id
      v_type == local_residency ? show_residency_response(person, record) : show_ssa_dhs_response(person, record)
    end
  end

  def show_residency_request(person, record)
    raw_request = person.consumer_role.local_residency_requests.select{
        |request| request.id == BSON::ObjectId.from_string(record.event_request_record_id)
    }
    raw_request.any? ? Nokogiri::XML(raw_request.first.body) : "no request record"
  end

  def show_deceased_verification_response(person, history)
    return unless history.event_response_record_id

    event_response = person.consumer_role.alive_status_responses.select{ |response| response.id == BSON::ObjectId.from_string(history.event_response_record_id) }.first
    event_response.present? ? JSON.parse(event_response.body) : "no response record"
  end

  def show_ssa_dhs_request(person, record)
    requests = person.consumer_role.lawful_presence_determination.ssa_requests + person.consumer_role.lawful_presence_determination.vlp_requests
    raw_request = requests.select{|request| request.id == BSON::ObjectId.from_string(record.event_request_record_id)} if requests.any?
    raw_request.any? ? Nokogiri::XML(raw_request.first.body) : "no request record"
  end

  def show_residency_response(person, record)
    raw_response = person.consumer_role.local_residency_responses.select{
        |response| response.id == BSON::ObjectId.from_string(record.event_response_record_id)
    }
    raw_response.any? ? Nokogiri::XML(raw_response.first.body) : "no response record"
  end

  def show_ssa_dhs_response(person, record)
    responses = person.consumer_role.lawful_presence_determination.ssa_responses + person.consumer_role.lawful_presence_determination.vlp_responses
    raw_response = responses.select{|response| response.id == BSON::ObjectId.from_string(record.event_response_record_id)} if responses.any?
    return "no response record" unless raw_response.any?

    EnrollRegistry.feature_enabled?(:ssa_h3) ? JSON.parse(raw_response.first.body) : Nokogiri::XML(raw_response.first.body)
  rescue JSON::ParserError => e
    Rails.logger.info("JSON parse failed with error #{e}. Trying Nokogiri XML parse") unless Rails.env.test?
    Nokogiri::XML(raw_response.first.body)
  rescue Nokogiri::XML::SyntaxError => e
    Rails.logger.info("Nokogiri XML parse failed with error #{e}. Trying JSON parse") unless Rails.env.test?
    JSON.parse(raw_response.first.body)
  end

  def display_documents_tab?(family_members, person)
    family_members ||= person&.primary_family&.family_members
    any_members_with_consumer_role?(family_members)
  end

  def any_members_with_consumer_role?(family_members)
    family_members.present? && family_members.map(&:person).any?(&:has_active_consumer_role?)
  end

  def has_active_resident_members?(family_members)
    family_members.present? && family_members.map(&:person).any?(&:is_resident_role_active?)
  end

  def has_active_consumer_dependent?(person,dependent)
    person.consumer_role && person.is_consumer_role_active? && (dependent.try(:family_member).try(:person).nil? || dependent.try(:family_member).try(:person).is_consumer_role_active?)
  end

  def has_active_resident_dependent?(person,dependent)
    (dependent.try(:family_member).try(:person).nil? || dependent.try(:family_member).try(:person).is_resident_role_active?)
  end

  def ridp_type_unverified?(ridp_type, person)
    ridp_type_status(ridp_type, person) != 'valid'
  end
end
