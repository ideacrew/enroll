
module Effective
  module Datatables
    class GeneralAgencyFamilyDataTable < Effective::MongoidDatatable

      datatable do
        table_column :name, :label => 'Name', :proc => Proc.new { |row| 
          pp = row.primary_applicant.person
          link_to pp.full_name, resume_enrollment_exchanges_agents_path(person_id: pp.id)
           }, :filter => false, :sortable => false

        table_column :ssn, :label => 'SSN', :proc => Proc.new { |row| 
           begin
             pp = row.primary_applicant.person.full_name
             number_to_obscured_ssn(pp.ssn)
           rescue
           end
         }, :filter => false, :sortable => false

        table_column :dob, :label => 'DOB', :proc => Proc.new { |row| 
          pp = row.primary_applicant.person
          format_date(pp.dob) }, :filter => false, :sortable => false
        
        table_column :hbx_id, :label => 'HBX ID', :proc => Proc.new { |row|
         pp = row.primary_applicant.person
         pp.hbx_id  }, :filter => false, :sortable => false
        
        table_column :family_ct, :label => 'Family Ct', :proc => Proc.new { |row| row.active_family_members.size }, :filter => false, :sortable => false
        
        table_column :consumer, :label => 'Consumer?', :proc => Proc.new {  |row|  
          pp = row.primary_applicant.person
          pp.consumer_role.present?  ? "Yes" : "No"}, :filter => false, :sortable => false

        table_column :employee, :label => 'Employee?', :proc => Proc.new {  |row|  
          pp = row.primary_applicant.person
          pp.employee_roles.present?  ? "Yes" : "No" }, :filter => false, :sortable => false
      end

      scopes do
         # scope :legal_name, "Hello"
      end

      def collection
          general_agency_profile = GeneralAgencyProfile.find(attributes[:id])
          @families = Family.scoped
        # @families = general_agency_profile.families

      end

      def global_search?
        true
      end

      def nested_filter_definition
   
      end

    end
  end
end
