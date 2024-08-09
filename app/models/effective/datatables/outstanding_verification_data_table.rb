# frozen_string_literal: true

module Effective
  module Datatables
    # datatable for outstanding verifications
    class OutstandingVerificationDataTable < Effective::MongoidDatatable
      include ApplicationHelper

      datatable do
        if EnrollRegistry.feature_enabled?(:include_faa_outstanding_verifications)
          load_eligibility_determination_columns
        else
          load_verification_type_columns
        end
      end

      def load_verification_type_columns
        table_column :name, :label => 'Name', :proc => proc { |row|
          link_to_with_noopener_noreferrer(h(row.primary_applicant.person.full_name), resume_enrollment_exchanges_agents_path(person_id: row.primary_applicant.person.id))
        }, :filter => false, :sortable => true
        table_column :dob, :label => 'DOB', :proc => proc { |row| format_date(row.primary_applicant.person.dob)}, :filter => false, :sortable => false
        table_column :hbx_id, :label => 'HBX ID', :proc => proc { |row| row.primary_applicant.person.hbx_id }, :filter => false, :sortable => false
        table_column :count, :label => 'Count', :width => '100px', :proc => proc { |row| row.active_family_members.size }, :filter => false, :sortable => false
        table_column :documents_uploaded, :label => 'Documents Uploaded', :proc => proc { |row| row.vlp_documents_status}, :filter => false, :sortable => true
        table_column :verification_due, :label => 'Verification Due',:proc => proc { |row|  format_date(row.best_verification_due_date) || format_date(default_verification_due_date) }, :filter => false, :sortable => true
        table_column :outstanding_verification_types, :label => 'Outstanding Verification Types',:proc => proc { |row|  outstanding_person_verification_types(row) }, :filter => false, :sortable => false
        table_column :actions, :width => '50px', :proc => proc { |row|
          dropdown = [
           ["Review", show_docs_documents_path(:person_id => row.primary_applicant.person.id),"static"]
          ]
          render partial: 'datatables/shared/dropdown', locals: {dropdowns: dropdown, row_actions_id: "family_actions_#{row.id}"}, formats: :html
        }, :filter => false, :sortable => false
      end

      def load_eligibility_determination_columns
        table_column :name, :label => 'Name', :proc => proc { |row|
          link_to_with_noopener_noreferrer(eligibility_primary_name(row), resume_enrollment_exchanges_agents_path(person_id: eligibility_primary_family_member(row).person_id))
        }, :filter => false, :sortable => true
        table_column :dob, :label => 'DOB', :proc => proc { |row| format_date(eligibility_primary_family_member(row).dob)}, :filter => false, :sortable => false
        table_column :hbx_id, :label => 'HBX ID', :proc => proc { |row| eligibility_primary_family_member(row).hbx_id }, :filter => false, :sortable => false
        table_column :count, :label => 'Count', :width => '100px', :proc => proc { |row| eligibility_enrolled_family_members(row).count }, :filter => false, :sortable => false
        table_column :documents_uploaded, :label => 'Documents Uploaded', :proc => proc { |row| document_status_for(row)}, :filter => false, :sortable => true
        table_column :verification_due, :label => 'Verification Due',:proc => proc { |row|  format_date(eligibility_earliest_due_date(row)) || format_date(default_verification_due_date) }, :filter => false, :sortable => true
        table_column :outstanding_verification_types, :label => 'Outstanding Verification Types',:proc => proc { |row|  outstanding_verification_types(row) }, :filter => false, :sortable => false
        table_column :actions, :width => '50px', :proc => proc { |row|
          dropdown = [
           ["Review", show_docs_documents_path(:person_id => eligibility_primary_family_member(row).person_id),"static"]
          ]
          render partial: 'datatables/shared/dropdown', locals: {dropdowns: dropdown, row_actions_id: "family_actions_#{row.id}"}, formats: :html
        }, :filter => false, :sortable => false
      end

      def collection
        unless (defined? @families) && @families.present? #memoize the wrapper class to persist @search_string
          @families = if EnrollRegistry.feature_enabled?(:include_faa_outstanding_verifications)
                        Queries::EligibilitiesOutstandingVerificationDatatableQuery.new(attributes)
                      else
                        Queries::OutstandingVerificationDatatableQuery.new(attributes)
                      end
        end
        @families
      end

      def global_search?
        true
      end

      def decrypt_ssn(val)
        SymmetricEncryption.decrypt(val)
      end

      def date_filter_name_definition
        "Verification Due Date Range"
      end

      def eligibility_primary_family_member(family)
        family.eligibility_determination.subjects.where(:is_primary => true).first
      end

      def eligibility_primary_name(family)
        primary_family_member = eligibility_primary_family_member(family)
        "#{primary_family_member.first_name} #{primary_family_member.last_name}"
      end

      def eligibility_primary_ssn(family)
        encrypted_ssn = eligibility_primary_family_member(family).encrypted_ssn
        decrypt_ssn(encrypted_ssn) if encrypted_ssn.present?
      end

      def eligibility_enrolled_family_members(family)
        family.eligibility_determination.subjects.where(:"eligibility_states.outstanding_verification_status".ne => 'not_enrolled')
      end

      def document_status_for(family)
        family.eligibility_determination.outstanding_verification_document_status
      end

      def subject_is_ov_eligible(subject)
        enrolled = false

        subject[:eligibility_states].each do |eligibility_state|
          eligibility_key = eligibility_state[:key]
          enrolled = true if %w[health_product_enrollment_status dental_product_enrollment_status].include?(eligibility_key) && eligibility_state[:evidence_states].present?
        end

        return 'not_enrolled' unless enrolled
        return 'eligible' if subject[:eligibility_states].all?{|eligibility_state| eligibility_state[:is_eligible]}
        return 'outstanding' if subject[:eligibility_states].any?{|eligibility_state| eligibility_state[:document_status] == 'Partially Uploaded'}
        'pending'
      end

      def eligibility_earliest_due_date(family)
        family.eligibility_determination.outstanding_verification_earliest_due_date
      end

      def outstanding_person_verification_types(family)
        family.family_members.inject([]) do |result, fm|
          result << fm.person.verification_types.where(:validation_status.in => ['outstanding', 'review', 'rejected']).map(&:type_name)
          result
        end.flatten.uniq
      end

      def outstanding_verification_types(family)
        subjects = family.eligibility_determination.subjects
        outstanding_legacy_verification_types = outstanding_legacy_verification_types(subjects)
        outstanding_evidence_types = outstanding_evidence_types(subjects)

        (outstanding_legacy_verification_types + outstanding_evidence_types).map(&:to_s).map(&:humanize).join(', ')
      rescue StandardError => e
        Rails.logger.error { "Error while pulling outstanding verification types #{e}" }
        "Error: #{e}"
      end

      def outstanding_legacy_verification_types(subjects)
        subjects.inject([]) do |result, subject|
          eligibility_state = subject.eligibility_states.where(eligibility_item_key: 'aca_individual_market_eligibility').first
          next result if eligibility_state.blank?

          result << eligibility_state.evidence_states.where(:status.in => [:outstanding, :in_review, :rejected]).map(&:evidence_item_key)
          result
        end.flatten.uniq
      end

      def outstanding_evidence_types(subjects)
        subjects.inject([]) do |result, subject|
          eligibility_state = subject.eligibility_states.where(eligibility_item_key: 'aptc_csr_credit').first
          next result if eligibility_state.blank?

          result << eligibility_state.evidence_states.where(:status.in => [:outstanding, :in_review, :rejected]).map(&:evidence_item_key)
          result
        end.flatten.uniq
      end

      def verification_type_nested_filters
        [
          {scope: 'vlp_fully_uploaded', label: 'Fully Uploaded', title: "Documents to review for all outstanding verifications"},
          {scope: 'vlp_partially_uploaded', label: 'Partially Uploaded', title: "Documents to review for some outstanding verifications"},
          {scope: 'vlp_none_uploaded', label: 'None Uploaded', title: "No documents to review"},
          {scope: 'all', label: 'All', title: "All outstanding verifications"}
        ]
      end

      def eligibility_determination_nested_filters
        [
          {scope: 'eligibility_determination_fully_uploaded', label: 'Fully Uploaded', title: "Documents to review for all outstanding verifications"},
          {scope: 'eligibility_determination_partially_uploaded', label: 'Partially Uploaded', title: "Documents to review for some outstanding verifications"},
          {scope: 'eligibility_determination_none_uploaded', label: 'None Uploaded', title: "No documents to review"},
          {scope: 'all', label: 'All', title: "All outstanding verifications"}
        ]
      end

      def default_verification_due_date
        verification_document_due = EnrollRegistry[:verification_document_due_in_days].item
        TimeKeeper.date_of_record + verification_document_due.days
      end

      def nested_filter_definition
        document_uploaded_filters = if EnrollRegistry.feature_enabled?(:include_faa_outstanding_verifications)
                                      eligibility_determination_nested_filters
                                    else
                                      verification_type_nested_filters
                                    end
        {
          documents_uploaded: document_uploaded_filters,
          top_scope: :documents_uploaded
        }
      end

      def authorized?(current_user, _controller, _action, _resource)
        current_user.has_hbx_staff_role?
      end
    end
  end
end
