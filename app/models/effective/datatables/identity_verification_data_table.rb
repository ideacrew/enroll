
module Effective
  module Datatables
    class IdentityVerificationDataTable < Effective::MongoidDatatable
      datatable do
        table_column :name, :label => 'Name', :proc => Proc.new { |row| link_to row.full_name, resume_enrollment_exchanges_agents_path(person_id: row.id) }, :filter => false, :sortable => false
        table_column :ssn, :label => 'SSN', :proc => Proc.new { |row| truncate(number_to_obscured_ssn(row.ssn))}, :filter => false, :sortable => false
        table_column :dob, :label => 'DOB', :proc => Proc.new { |row| row.dob }, :filter => false, :sortable => false
        table_column :hbx_id, :label => 'HBX ID', :proc => Proc.new { |row| row.hbx_id }, :filter => false, :sortable => false
        table_column :count, :label => 'Count', :width => '100px', :proc => Proc.new { |row| row.primary_family.active_family_members.size  }, :filter => false, :sortable => false
        table_column :document_type, :label => 'Document Type', :proc => proc { |row| link_to document_type(row), document_uploaded_path(row) }, :filter => false, :sortable => false
        table_column :date_uploaded, :label => "Date Uploaded", :width => '100px', :proc => proc { |row| document_uploaded_date(row) }, :filter => false, :sortable => false
      end

      scopes do
         scope :legal_name, "Hello"
      end

      def collection
        unless  (defined? @families) && @families.present?   #memoize the wrapper class to persist @search_string
          @families = Queries::IdentityVerificationDatatableQuery.new(attributes)
        end
        @families
      end

      def global_search?
        true
      end

      def document_uploaded_path(row)
        if EnrollRegistry.feature_enabled?(:ridp_h139)
          Rails.application.routes.url_helpers.failed_validation_insured_fdsh_ridp_verifications_path(person_id: row.id)
        else
          Rails.application.routes.url_helpers.failed_validation_insured_interactive_identity_verifications_path(person_id: row.id)
        end
      end

      def document_type(row)
        role = row.consumer_role

        is_identity = ['pending', 'rejected'].include? role.identity_validation
        is_application = ['pending', 'rejected'].include? role.application_validation

        return 'Identity/Application' if is_identity && is_application
        return 'Identity' if is_identity
        return 'Application' if is_application
      end
      
      def document_uploaded_date(row)
        role = row.consumer_role
        identity_validation = role.identity_validation
        application_validation = role.application_validation

        if ['pending', 'rejected'].include? identity_validation
          ridp_document = role.ridp_documents.where(ridp_verification_type: "Identity").last
          ridp_document.present? && ridp_document.uploaded_at.present? ? ridp_document.uploaded_at : ""
        elsif ['pending', 'rejected'].include? application_validation
          ridp_document = role.ridp_documents.where(ridp_verification_type: "Application").last
          ridp_document.present? && ridp_document.uploaded_at.present? ? ridp_document.uploaded_at : ""
        end
      end
    end
  end
end
