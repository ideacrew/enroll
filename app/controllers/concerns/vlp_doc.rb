module VlpDoc
  def vlp_doc_params_list
    [
      {:consumer_role =>
       [:vlp_documents_attributes =>
        [:subject, :citizenship_number, :naturalization_number,
         :alien_number, :passport_number, :sevis_id, :visa_number,
         :receipt_number, :expiration_date, :card_number,
         :i94_number, :country_of_citizenship]]}
    ]
  end

  def update_vlp_documents(consumer_role, from='person', dependent=nil)
    return true if consumer_role.blank?

    if (params[from][:naturalized_citizen] == "true" || params[from][:eligible_immigration_status] == "true") && (params[from][:consumer_role].blank? || params[from][:consumer_role][:vlp_documents_attributes].blank?)
      if from == 'person'
        add_document_errors_to_consumer_role(consumer_role, ["document type", "cannot be blank"])
      elsif from == 'dependent' and dependent.present?
        add_document_errors_to_dependent(dependent, ["document type", "cannot be blank"])
      end
      return false
    end

    if params[from][:consumer_role] && params[from][:consumer_role][:vlp_documents_attributes]
      doc_params = params.require(from).permit(*vlp_doc_params_list)
      vlp_doc_attribute = doc_params[:consumer_role][:vlp_documents_attributes].first.last
      @vlp_doc_subject = vlp_doc_attribute[:subject]
      document = find_document(consumer_role, @vlp_doc_subject)
      document.update_attributes(vlp_doc_attribute)
      if from == 'person'
        add_document_errors_to_consumer_role(consumer_role, document)
      elsif from == 'dependent' and dependent.present?
        add_document_errors_to_dependent(dependent, document)
      end
      return document.errors.blank?
    else
      return true
    end
  end
end
