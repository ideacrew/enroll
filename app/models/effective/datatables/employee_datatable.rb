
module Effective
  module Datatables
    class EmployeeDatatable < Effective::MongoidDatatable

      datatable do

         bulk_actions_column do
          bulk_action 'Generate Invoice', generate_invoice_exchanges_hbx_profiles_path, data: { confirm: 'Generate Invoices?', no_turbolink: true }
          bulk_action 'Mark Binder Paid', binder_paid_exchanges_hbx_profiles_path, data: {  confirm: 'Mark Binder Paid?', no_turbolink: true }
        end

        table_column :EmployeeName, :proc => Proc.new { |row|
          row.first_name
        }, :sortable => false, :filter => false

         table_column :DOB, :proc => Proc.new { |row|
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

         table_column :EnrollmentStatus, :proc => Proc.new { |row|
           enrollment_state(row)
         }, :sortable => false, :filter => false

         table_column :preliminaryEnroll, :width => '50px', :proc => Proc.new { |row|
           dropdown = [
               # Link Structure: ['Link Name', link_path(:params), 'link_type'], link_type can be 'ajax', 'static', or 'disabled'
               ['Employee will enroll', transmit_group_xml_exchanges_hbx_profile_path(row.employer_profile), 'static'],
               ['Employee will not enroll with valid waiver', generate_invoice_exchanges_hbx_profiles_path(ids: [row]), 'static'],
               ['Employee will not enroll with invalid waiver', generate_invoice_exchanges_hbx_profiles_path(ids: [row]), 'static']
           ]
           render partial: 'datatables/shared/simple_enroll_status', locals: {dropdowns: dropdown, row_actions_id: "family_actions_#{row.id.to_s}"}, formats: :html
         }, :filter => false, :sortable => false

         table_column :actions, :width => '50px', :proc => Proc.new { |row|
           dropdown = [
               # Link Structure: ['Link Name', link_path(:params), 'link_type'], link_type can be 'ajax', 'static', or 'disabled'
               ['Edit', transmit_group_xml_exchanges_hbx_profile_path(row.employer_profile), 'static'],
               ['Terminate', generate_invoice_exchanges_hbx_profiles_path(ids: [row]), 'static']
           ]
           render partial: 'datatables/shared/dropdown', locals: {dropdowns: dropdown, row_actions_id: "family_actions_#{row.id.to_s}"}, formats: :html
         }, :filter => false, :sortable => false

      end

      def generate_invoice_link_type(row)
        # row.current_month_invoice.present? ? 'disabled' : 'post_ajax'
      end

      def collection
        return @employee_collection if defined? @employee_collection
        employer_profile = EmployerProfile.find(attributes["id"])
        @emplee_profile = employer_profile
        # if attributes[:employers].present? && !['all'].include?(attributes[:employers])
        #   employers = employers.send(attributes[:employers]) if ['employer_profiles_applicants','employer_profiles_enrolling','employer_profiles_enrolled'].include?(attributes[:employers])
        #   employers = employers.send(attributes[:enrolling]) if attributes[:enrolling].present?
        #   employers = employers.send(attributes[:enrolling_initial]) if attributes[:enrolling_initial].present?
        #   employers = employers.send(attributes[:enrolling_renewing]) if attributes[:enrolling_renewing].present?
        #
        #   employers = employers.send(attributes[:enrolled]) if attributes[:enrolled].present?
        #
        #   if attributes[:upcoming_dates].present?
        #     if date = Date.strptime(attributes[:upcoming_dates], "%m/%d/%Y")
        #       employers = employers.employer_profile_plan_year_start_on(date)
        #     end
        #   end
        #
        # end
        @employee_collection = employer_profile.census_employees.active

      end

      def global_search?
        true
      end

      def global_search_method
        val = params[:search][:value]
        if val.match(/\d{9}/)
          :datatable_search_fein
        else
          :datatable_search
        end
      end

      def search_column(collection, table_column, search_term, sql_column)
        if table_column[:name] == 'legal_name'
          collection.datatable_search(search_term)
        elsif table_column[:name] == 'fein'
          collection.datatable_search_fein(search_term)
        elsif table_column[:name] == 'conversion'
          if search_term == "Yes"
            collection.datatable_search_employer_profile_source("conversion")
          elsif search_term == "No"
            collection.datatable_search_employer_profile_source("self_serve")
          else
            super
          end
        else
          super
        end
      end

      def nested_filter_definition

        @next_30_day = TimeKeeper.date_of_record.next_month.beginning_of_month
        @next_60_day = @next_30_day.next_month
        @next_90_day = @next_60_day.next_month

        filters = {
            enrolling_renewing:
                [
                    {scope: 'employer_profiles_renewing_application_pending', label: 'Application Pending'},
                    {scope: 'employer_profiles_renewing_open_enrollment', label: 'Open Enrollment'},
                ],
            enrolling_initial:
                [
                    {scope: 'employer_profiles_initial_application_pending', label: 'Application Pending'},
                    {scope: 'employer_profiles_initial_open_enrollment', label: 'Open Enrollment'},
                    {scope: 'employer_profiles_binder_pending', label: 'Binder Pending'},
                    {scope: 'employer_profiles_binder_paid', label: 'Binder Paid'},
                ],
            enrolled:
                [
                    {scope:'employer_profiles_enrolled', label: 'All' },
                    {scope:'employer_profiles_suspended', label: 'Suspended' },
                ],
            upcoming_dates:
                [
                    {scope: @next_30_day, label: @next_30_day },
                    {scope: @next_60_day, label: @next_60_day },
                    {scope: @next_90_day, label: @next_90_day },
                #{scope: "employer_profile_plan_year_start_on('#{@next_60_day})'", label: @next_60_day },
                #{scope: "employer_profile_plan_year_start_on('#{@next_90_day})'",  label: @next_90_day },
                ],
            enrolling:
                [
                    {scope: 'employer_profiles_enrolling', label: 'All'},
                    {scope: 'employer_profiles_initial_eligible', label: 'Initial', subfilter: :enrolling_initial},
                    {scope: 'employer_profiles_renewing', label: 'Renewing / Converting', subfilter: :enrolling_renewing},
                    {scope: 'employer_profiles_enrolling', label: 'Upcoming Dates', subfilter: :upcoming_dates},
                ],
            employers:
                [
                    {scope:'all', label: 'All'},
                    {scope:'employer_profiles_applicants', label: 'Active'},
                    {scope:'employer_profiles_enrolling', label: 'Terminated', subfilter: :enrolling},
                    {scope:'employer_profiles_enrolled', label: 'COBRA Continuation', subfilter: :enrolled},
                ],
            top_scope: :employers
        }

      end
    end
  end
end
