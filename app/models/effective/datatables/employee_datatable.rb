
module Effective
  module Datatables
    class EmployeeDatatable < Effective::MongoidDatatable

      datatable do

        # TODO: Implement Filters here
        bulk_actions_column do
          bulk_action 'Employee will enroll', generate_invoice_exchanges_hbx_profiles_path, data: { confirm: 'Generate Invoices?', no_turbolink: true }
          bulk_action 'Employee will not enroll with valid waiver', binder_paid_exchanges_hbx_profiles_path, data: {  confirm: 'Mark Binder Paid?', no_turbolink: true }
          bulk_action 'Employee will not enroll with invalid waiver', generate_invoice_exchanges_hbx_profiles_path, data: { confirm: 'Generate Invoices?', no_turbolink: true }
        end

        table_column :EmployeeName, :width => '50px', :proc => Proc.new { |row|
          (link_to row.full_name, employers_employer_profile_path(@employer_profile, :tab=>'home')) + raw("<br>")
        }, :sortable => false, :filter => false

         table_column :dob, :label => 'DOB', :proc => Proc.new { |row|
           row.dob
         }, :sortable => false, :filter => false

         table_column :Hired, :proc => Proc.new { |row|
           row.hired_on
         }, :sortable => false, :filter => false

         table_column :status, :proc => Proc.new { |row|
           employee_state_format(row.aasm_state, row.employment_terminated_on)
         }, :sortable => false, :filter => false

         table_column :BenefitPackage, :proc => Proc.new { |row|
           row.active_benefit_group_assignment.benefit_group.title.capitalize if row.active_benefit_group_assignment.present?
         }, :sortable => false, :filter => false

        if attributes["renewal"]
          table_column :renewalbenefitpackage, :label => 'Renewal Benefit Package', :proc => Proc.new { |row|
            row.renewal_benefit_group_assignment.benefit_group.title.capitalize if row.active_benefit_group_assignment.present?
          }, :filter => false, :sortable => false
        end

        if attributes["terminated"]
          table_column :TerminationDate, :proc => Proc.new{ |row|
            row.employment_terminated_on
          }, :filter => false, :sortable => false
        end

         table_column :EnrollmentStatus, :proc => Proc.new { |row|
           enrollment_state(row)
         }, :sortable => false, :filter => false

        if attributes["renewal_status"]
          table_column :RenewalEnrollmentStatus, :proc => Proc.new{ |row|
            renewal_enrollment_state(row)
          }, :filter => false, :sortable => false
        end

         table_column :Action, :width => '50px', :proc => Proc.new { |row|
           dropdown = [
               ['Edit', edit_employers_employer_profile_census_employee_path(@employer_profile, row.id), 'static'],
               ['Terminate', generate_invoice_exchanges_hbx_profiles_path(ids: [row]), 'static'],
               ['Rehire', generate_invoice_exchanges_hbx_profiles_path(ids: [row]), 'static'],
               ['Initiate Cobra', generate_invoice_exchanges_hbx_profiles_path(ids: [row]), 'static']
           ]
           render partial: 'datatables/shared/dropdown', locals: {dropdowns: dropdown, row_actions_id: "family_actions_#{row.id.to_s}"}, formats: :html
         }, :filter => false, :sortable => false
      end

      def collection
        return @employee_collection if defined? @employee_collection
        employer_profile = EmployerProfile.find(attributes["id"])
        @employer_profile = employer_profile
        @employee_collection = employer_profile.census_employees.active
      end

      def nested_filter_definition
        filters = {
            employers:
                [
                    {scope:'all', label: 'Active & COBRA'},
                    {scope:'employer_profiles_applicants', label: 'Active only'},
                    {scope:'employer_profiles_COBRA', label: 'COBRA only'},
                    {scope:'employer_profiles_terminated', label: 'Terminated'},
                    {scope:'employer_profiles_enrolled', label: 'All'}
                ],
            top_scope: :employers
        }
      end
    end
  end
end
