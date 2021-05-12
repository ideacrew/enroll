# frozen_string_literal: true

module GoldenSeedFinancialAssistanceHelper
  def create_and_return_fa_application(completed_person_attributes = {})
    application = FinancialAssistance::Application.new
    application.save!
    application
  end

  def create_and_return_fa_applicant(case_info_hash)
    applicant = case_info_hash[:fa_application].applicants.build
    target_person = case_info_hash[:person_attributes][:current_target_person]
    applicant.first_name = target_person.first_name
    applicant.middle_name = target_person.middle_name
    applicant.last_name = target_person.last_name
    applicant.gender = target_person.gender
    applicant.dob = target_person.dob
    applicant.is_consumer_role = target_person.consumer_role.present?
    applicant.save!
    applicant
  end

  def add_applicant_income(case_info_hash)
    income = case_info_hash[:target_fa_applicant].incomes.build
    income.amount = case_info_hash[:person_attributes][:amount]
    income.frequency = case_info_hash[:person_attributes][:frequency]
    income.from = case_info_hash[:person_attributes][:from]
    income.save!
    income
  end
end
