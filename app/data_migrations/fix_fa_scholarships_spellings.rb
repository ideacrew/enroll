# frozen_string_literal: true

require File.join(Rails.root, "lib/mongoid_migration_task")

# A small specific class for fixing a typo in incomes
class FixFaScholarshipsSpellings < MongoidMigrationTask
  def migrate
    abort("Financial Assistance not configured.") unless EnrollRegistry.feature_enabled?(:financial_assistance)
    misspelled_incomes = ::FinancialAssistance::Application.all.flat_map(&:applicants).flat_map(&:incomes).select do |income|
      income.kind == 'scholorship_payments'
    end
    abort("No misspelled scholarship incomes present.") if misspelled_incomes.blank?
    puts("#{misspelled_incomes.count} misspelled scholarship")
    misspelled_incomes.each do |income|
      income.update_attributes!(kind: "scholarship_payments")
    end
    puts("Incomes spelling update rake complete.")
  end
end