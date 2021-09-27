# frozen_string_literal: true

require File.join(Rails.root, "lib/mongoid_migration_task")

# A small specific class for fixing a typo in incomes
class FixFaScholarshipsSpellings < MongoidMigrationTask
  def migrate
    abort("Financial Assistance not configured.") unless EnrollRegistry.feature_enabled?(:financial_assistance)
    apps_with_misspelled_income_kind = FinancialAssistance::Application.where(:"applicants.incomes.kind" => 'scholorship_payments')
    apps_with_misspelled_income_kind.each do |application|
      application.applicants.where(:"incomes.kind" => 'scholorship_payments').each do |applicant|
        applicant.incomes.where(kind: 'scholorship_payments').each { |income| income.update_attributes!(kind: 'scholarship_payments') }
      end
    end
    puts("Incomes spelling update rake complete.")
  end
end
