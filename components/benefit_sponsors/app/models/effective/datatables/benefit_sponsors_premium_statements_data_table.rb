module Effective
  module Datatables
    class BenefitSponsorsPremiumStatementsDataTable < Effective::MongoidDatatable
      attr_accessor :enrollment_ids
      datatable do
        table_column :full_name, label: "Employee Profile",
          :proc => Proc.new { |row|
            # update this datatable to include dental too
            @enrollment = row.active_household.hbx_enrollments.where(:"_id".in => enrollment_ids).first
            content_tag(:span, class: 'name') do
            name_to_listing(@enrollment.employee_role.person)
          end +
          content_tag(:span, content_tag(:p, "DOB: #{format_date @enrollment.employee_role.person.dob}")) +
          content_tag(:span, content_tag(:p, "SSN: #{number_to_obscured_ssn @enrollment.employee_role.person.ssn}")) +
          content_tag(:span, "HIRED:  #{format_date @enrollment.employee_role.census_employee.hired_on}")
          }, :filter => false, :sortable => false
        
        table_column :title, :label => 'Benefit Package',
          :proc => Proc.new { |row|
            content_tag(:span, class: 'benefit-group') do
              @enrollment.benefit_group.title.try(:titleize)
            end
          }, :filter => false, :sortable => false

        table_column :coverage_kind,:label => 'Insurance Coverage',
        :proc => Proc.new { |row|
          content_tag(:span) do
            content_tag(:span, class: 'name') do
              mixed_case(@enrollment.coverage_kind)
            end +
            content_tag(:span) do
              " | # Dep(s) Covered: ".to_s + @enrollment.humanized_dependent_summary.to_s
            end +
            # content_tag(:p, (hbx.plan.carrier_profile.legal_name.to_s + " -- " + hbx.plan.name.to_s))
            content_tag(:p, ("toDo"))
          end
        }, :filter => false, :sortable => false

        table_column :cost,:label => 'COST',
        :proc => Proc.new { |row|
          content_tag(:span, "Employer Contribution: ".to_s + (number_to_currency @enrollment.total_employer_contribution.to_s)) +
          content_tag(:div) do 
            "Employee Contribution:".to_s + (number_to_currency number_to_currency @enrollment.total_employee_cost) 
          end  +
          content_tag(:p,  content_tag(:strong, "Total:") +  content_tag(:strong, @enrollment.total_premium))
        }, :filter => false, :sortable => false
      end


      def collection
        return @collection if defined? @collection
        @employer_profile = BenefitSponsors::Organizations::Profile.find(attributes[:id])
        query = BenefitSponsors::Queries::PremiumStatementsQuery.new(@employer_profile, attributes[:billing_date])
        @enrollment_ids, @families = query.execute
        @families
      end

      def global_search?
        false
      end
    end
  end
end
