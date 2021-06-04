# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module FinancialAssistance
  module Operations
    module Applicant
      #This class calculated net annual income for a applicant
      # Net Annual Income = Total Incomes - Total Deductions
      class CalculateAndPersistNetAnnualIncome
        include Dry::Monads[:result, :do]

        # @param [applicant object] input
        #
        # @return [applicant]
        def call(params)
          applicant = yield validate(params)
          total_annual_income = yield calculate_total_annual_income(applicant)
          total_deductions = yield calculate_total_deductions_income(applicant)
          total_net_income = yield calculate_net_income(total_annual_income, total_deductions)
          result = yield persist(applicant, total_net_income)

          Success(result)
        end

        private

        def validate(params)
          if params[:applicant].present? && params[:applicant].is_a?(FinancialAssistance::Applicant)
            Success(params[:applicant])
          else
            Failure("Invalid applicant")
          end
        end

        def calculate_total_annual_income(applicant)
          return Success(BigDecimal('0')) unless applicant.incomes

          total_income = applicant.incomes.inject(0) do |total, income|
            total + annual_employee_cost(income.frequency_kind, income.amount)
          end
          Success(total_income)
        end

        def calculate_total_deductions_income(applicant)
          return Success(BigDecimal('0')) unless applicant.deductions

          total_deductions = applicant.deductions.inject(0) do |total, deduction|
            total + annual_employee_cost(deduction.frequency_kind, deduction.amount)
          end
          Success(total_deductions)
        end

        def calculate_net_income(total_annual_income, total_deductions)
          Success(total_annual_income - total_deductions)
        end

        def persist(applicant, total_net_income)
          applicant.update_attributes(net_annual_income: total_net_income) unless applicant.net_annual_income == total_net_income
          Success(applicant)
        end

        def annual_employee_cost(employee_cost_frequency, employee_cost)
          return BigDecimal('0') if employee_cost_frequency.blank? || employee_cost.blank?
          case employee_cost_frequency
          when 'weekly' then (employee_cost * 52)
          when 'monthly' then (employee_cost * 12)
          when 'yearly' then employee_cost
          when 'biweekly' then (employee_cost * 26)
          when 'quarterly' then (employee_cost * 4)
          when 'daily' then (employee_cost * 5 * 52)
          when 'half_yearly' then (employee_cost * 2)
          else BigDecimal('0')
          end
        end
      end
    end
  end
end
