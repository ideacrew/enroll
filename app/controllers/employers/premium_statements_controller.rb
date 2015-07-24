require 'csv'
class Employers::PremiumStatementsController < ApplicationController

  def show
    @employer_profile = EmployerProfile.find(params.require(:id))
    @current_plan_year = @employer_profile.published_plan_year
    @hbx_enrollments = @current_plan_year.hbx_enrollments rescue []

    respond_to do |format| 
      format.html
      format.js
      format.csv do
        send_data(csv_for(@hbx_enrollments), type: csv_content_type, filename: "dchl_statement.csv")
      end
    end
  end

private

  def csv_for(hbx_enrollments)
    (output = "").tap do
      CSV.generate(output) do |csv|
        hbx_enrollments.each do |enrollment|
          ee = enrollment.subscriber.person.employee_roles.first.census_employee
          csv << [ee.full_name, ee.ssn, ee.dob, ee.hired_on, ee.published_benefit_group.title, "Health", enrollment.plan.name]
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