# frozen_string_literal: true

module FinancialAssistance
  module SharedHelper
    def show_component(url)
      if url.split('/')[2] == "consumer_role" || url.split('/')[1] == "insured" && url.split('/')[2] == "interactive_identity_verifications" || url.split('/')[1] == "financial_assistance" && url.split('/')[2] == "applications" || url.split('/')[1] == "insured" && url.split('/')[2] == "family_members" || url.include?("family_relationships")
        false
      else
        true
      end
    end

    def li_nav_classes_for(target) # rubocop:disable Metrics/CyclomaticComplexity, TODO: Remove this
      current = case controller_name
                when 'applications'
                  if action_name == 'edit'
                    :household_info
                  else
                    :review_and_submit
                  end
                when 'family_members'
                  :household_info
                when 'applicants'
                  case action_name
                  when 'tax_info'
                    :tax_info
                  when 'other_questions'
                    :other_questions
                  end
                when 'incomes'
                  if action_name == 'other'
                    :other_income
                  else
                    :income
                  end
                when 'deductions'
                  :income_adjustments
                when 'benefits'
                  :health_coverage
                when 'family_relationships'
                  :relationships
                end

      order = [:applications, :household_info, :relationships, :income_and_coverage, :tax_info, :income, :other_income, :income_adjustments, :health_coverage, :other_questions, :review_and_submit]

      if current.blank?
        ''
      elsif target == current
        'activer active'
      elsif order.index(target) < order.index(current)
        'activer'
      else
        ''
      end
    end
  end
end
