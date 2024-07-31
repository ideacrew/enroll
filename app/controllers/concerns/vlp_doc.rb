# frozen_string_literal: true

module VlpDoc
  include ErrorBubble
  include EventSource::Command

  def vlp_doc_params_list
    [
      {:consumer_role =>
       [:vlp_documents_attributes =>
        [:subject, :citizenship_number, :naturalization_number,
         :alien_number, :passport_number, :sevis_id, :visa_number,
         :receipt_number, :expiration_date, :card_number, :description,
         :i94_number, :country_of_citizenship]]}
    ]
  end

  def validate_vlp_params(params, source, consumer_role, dependent)
    if (params[source][:naturalized_citizen] == "true" || params[source][:eligible_immigration_status] == "true") && params[source][:consumer_role].present? && params[source][:consumer_role][:vlp_documents_attributes].present?
      vlp_doc_params = params.require(source).permit(vlp_doc_params_list).dig(:consumer_role, :vlp_documents_attributes, "0").delete_if {|_k, v| v.blank? }.to_h
      result = ::Validators::VlpV37Contract.new.call(vlp_doc_params)
      if result.failure? && source == 'person'
        invalid_key = result.errors.to_h.keys.first
        add_document_errors_to_consumer_role(consumer_role, ['Please fill in your information for', "#{invalid_field(invalid_key).to_s.titlecase}."])
        return false
      elsif result.failure? && source == 'dependent'
        invalid_key = result.errors.to_h.keys.first
        add_document_errors_to_dependent(dependent, ['Please fill in your information for', "#{invalid_field(invalid_key).to_s.titlecase}."])
        return false
      end
    end
    true
  end

  def invalid_field(invalid_key)
    invalid_key == :description ? :document_description : invalid_key
  end

  def update_vlp_documents(consumer_role, source = 'person', dependent = nil)
    return true if consumer_role.blank?
    return true if params[source][:is_applying_coverage] == "false"
    return false unless validate_vlp_params(params, source, consumer_role, dependent)
    if (params[source][:naturalized_citizen] == "true" || params[source][:eligible_immigration_status] == "true") &&
       (params[source][:consumer_role].blank? || params[source][:consumer_role][:vlp_documents_attributes].blank?) &&
       !FinancialAssistanceRegistry.feature_enabled?(:optional_document_fields)
      if source == 'person'
        add_document_errors_to_consumer_role(consumer_role, ["document type", "cannot be blank"])
      elsif source == 'dependent' && dependent.present?
        add_document_errors_to_dependent(dependent, ["document type", "cannot be blank"])
      end
      return false
    end
    if params[source][:consumer_role] && params[source][:consumer_role][:vlp_documents_attributes]
      if params[:dependent].present? && params[:dependent][:consumer_role][:vlp_documents_attributes]["0"].present? && params[:dependent][:consumer_role][:vlp_documents_attributes]["0"][:expiration_date].present?
        params[:dependent][:consumer_role][:vlp_documents_attributes]["0"][:expiration_date] = parse_date(params[:dependent][:consumer_role][:vlp_documents_attributes]["0"][:expiration_date])
      elsif params[:person].present? && params[:person][:consumer_role].present? && params[:person][:consumer_role][:vlp_documents_attributes]["0"].present? && params[:person][:consumer_role][:vlp_documents_attributes]["0"][:expiration_date].present?
        params[:person][:consumer_role][:vlp_documents_attributes]["0"][:expiration_date] = parse_date(params[:person][:consumer_role][:vlp_documents_attributes]["0"][:expiration_date])
      end

      doc_params = params.require(source).permit(*vlp_doc_params_list)
      vlp_doc_attribute = doc_params[:consumer_role][:vlp_documents_attributes]["0"]
      puts vlp_doc_attribute

      if vlp_doc_attribute
        document = consumer_role.find_document(vlp_doc_attribute[:subject])
        document.update_attributes(vlp_doc_attribute)
        consumer_role.update_attributes!(active_vlp_document_id: document.id) if document.present?
      end
      if source == 'person'
        add_document_errors_to_consumer_role(consumer_role, document)
      elsif source == 'dependent' && dependent.present?
        add_document_errors_to_dependent(dependent, document)
      end
      if document.present?
        document.errors.blank?
      else
        false
      end
    else
      true
    end
  end

  def get_vlp_doc_subject_by_consumer_role(consumer_role)
    consumer_role&.vlp_documents&.where(id: consumer_role.active_vlp_document_id)&.first&.subject
  end

  def sensitive_info_changed?(role)
    return unless role
    info_changed_params = if params[:person]
                            params.permit(:person => {})[:person].to_h
                          else
                            params.permit(:dependent => {})[:dependent].to_h
                          end
    info_changed = role.sensitive_information_changed?(info_changed_params)
    dc_status = (role.person.is_homeless || role.person.is_temporarily_out_of_state)
    [info_changed, dc_status]
  end

  def native_status_changed?(role)
    return unless role

    if EnrollRegistry.feature_enabled?(:indian_alaskan_tribe_codes)
      tribal_state = params.dig("person", "tribal_state")
      tribe_codes =  params.dig("person", "tribe_codes")
      tribal_name = params.dig("person", "tribal_name")
      tribal_id = params.dig("person", "tribal_id")

      if tribal_state == EnrollRegistry[:enroll_app].setting(:state_abbreviation).item
        role.person.tribe_codes != tribe_codes
      elsif tribal_id.present?
        role.person.tribal_id != tribal_id
      else
        role.person.tribal_name != tribal_name
      end
    else
      params_hash = params.permit("tribal_id").to_h
      role.person.tribal_id != params_hash["tribal_id"]
    end
  end

  # These methods are a fix to make sure that any associated events are
  # fired correctly.
  # It's placed here because:
  #   1. Embedded documents can frequently change the state of consumer
  #      roles, but those writes/changes can happen after the consumer
  #      role itself is updated.
  #   2. If we place the event broadcast into the embedded document itself,
  #      the result is a tremendous amount of thrashing when this update
  #      should actually be considered atomic.
  #   3. We have no desire right now to impact the behaviour of primary family
  #      members during the entry process.
  #
  # All of this logic should be refactored into the correct single operation
  # when this controller is corrected into the clean code pattern.

  def fire_consumer_roles_create_for_vlp_docs(consumer_role)
    event = event('events.individual.consumer_roles.created', attributes: { gid: consumer_role.to_global_id.uri })
    event.success.publish if event.success?
  rescue StandardError => e
    Rails.logger.error { "Couldn't generate consumer role create event due to #{e.backtrace}" }
  end

  def fire_consumer_roles_update_for_vlp_docs(consumer_role, original_applying_for_coverage)
    event = event('events.individual.consumer_roles.updated', attributes: { gid: consumer_role.to_global_id.uri, previous: {is_applying_coverage: original_applying_for_coverage} })
    event.success.publish if event.success?
  rescue StandardError => e
    Rails.logger.error { "Couldn't generate consumer role updated event due to #{e.backtrace}" }
  end

end
