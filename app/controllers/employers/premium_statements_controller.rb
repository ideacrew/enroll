require 'csv'
class Employers::PremiumStatementsController < ApplicationController
  layout "two_column", only: [:show]

  def show
    @employer_profile = EmployerProfile.find(params.require(:id))
    @current_plan_year = @employer_profile.find_plan_year_by_effective_date(TimeKeeper.date_of_record.next_month)

    valid_hbx_enrollments_by_billing_month = @current_plan_year.hbx_enrollments_by_month(TimeKeeper.date_of_record.next_month.end_of_month)
    @hbx_enrollments = valid_hbx_enrollments_by_billing_month.select{|enrollment| enrollment.census_employee.is_active?}.first(100)

    respond_to do |format|
      format.html
      format.js
      format.csv do
        send_data(csv_for(@hbx_enrollments), type: csv_content_type, filename: "DCHealthLink_Premium_Billing_Report.csv")
      end
    end
  end

private

  def csv_for(hbx_enrollments)
    (output = "").tap do
      CSV.generate(output) do |csv|
        csv << ["Name", "SSN", "DOB", "Hired On", "Benefit Group", "Type", "Name", "Issuer", "Covered Ct", "Employer Contribution",
        "Employee Premium", "Total Premium"]
        hbx_enrollments.each do |enrollment|
          ee = enrollment.census_employee
          next if ee.blank?
          csv << [  ee.full_name,
                    ee.ssn,
                    ee.dob,
                    ee.hired_on,
                    ee.published_benefit_group.title,
                    enrollment.plan.coverage_kind,
                    enrollment.plan.name,
                    enrollment.plan.carrier_profile.legal_name,
                    enrollment.humanized_members_summary,
                    view_context.number_to_currency(enrollment.total_employer_contribution),
                    view_context.number_to_currency(enrollment.total_employee_cost),
                    view_context.number_to_currency(enrollment.total_premium)
                  ]
        end
      end
    end
  end

  def csv_content_type
    case request.user_agent
      when /windows/i
        'application/vnd.ms-excel'
      else
        'text/csv'
    end
  end

end
