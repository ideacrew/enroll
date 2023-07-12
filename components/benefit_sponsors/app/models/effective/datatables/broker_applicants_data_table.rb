module Effective
  module Datatables
    class BrokerApplicantsDataTable < ::Effective::MongoidDatatable
      datatable do
        table_column :name, :label => 'Applicant Name', :proc => Proc.new { |row| row.full_name }, :filter => false, :sortable => false
        table_column :npn, :label => 'Applicant NPN', :proc => Proc.new { |row| row.broker_role.npn }, :filter => false, :sortable => false
        table_column :agency_name, :label => 'Agency Name', :proc => Proc.new { |row| row.broker_role.try(:broker_agency_profile).try(:legal_name) }, :filter => false, :sortable => false
        table_column :status, :label => 'Status', :proc => Proc.new { |row| row.broker_role.current_state }, :filter => false, :sortable => false
        table_column :submitted_date, :label => 'Submitted Date', :proc => Proc.new { |row| format_datetime row.broker_role.latest_transition_time }, :filter => false, :sortable => false

      end

      def collection
        unless  (defined? @people) && @people.present?
          @people = BenefitSponsors::Queries::BrokerApplicantsDatatableQuery.new(attributes)
        end
        @people
      end

      def global_search?
        true
      end

      def broker_agency_profile row
        row.broker_role.broker_agency_profile
      end

      def nested_filter_definition

      end

      def authorized?(current_user, _controller, _action, _resource)
        return false if current_user.blank?

        current_user.hbx_staff_role?
      end
    end
  end
end
