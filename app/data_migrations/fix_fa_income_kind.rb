# frozen_string_literal: true

require File.join(Rails.root, "lib/mongoid_migration_task")

# Class which updates all the income objects which have kind 'unemployment_insurance'
class FixFaIncomeKind < MongoidMigrationTask
  def migrate
    apps_with_incorrect_income_kind = FinancialAssistance::Application.where(:"applicants.incomes.kind" => 'unemployment_insurance')
    apps_with_incorrect_income_kind.each do |application|
      application.applicants.where(:"incomes.kind" => 'unemployment_insurance').each do |applicant|
        applicant.incomes.where(kind: 'unemployment_insurance').each { |income| income.update_attributes!(kind: 'unemployment_income') }
      end
    rescue StandardError => e
      Rails.logger.error "Unable to process application with hbx_id: #{application.hbx_id}, error: #{e.message}"
    end
  end
end
