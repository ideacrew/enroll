# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module FinancialAssistance
  module Operations
    module Applicant
      # This class calculates net annual income for an applicant
      # Net Annual Income = Total Incomes - Total Deductions
      class CalculateNetAnnualIncome
        include Dry::Monads[:do, :result]

        # @param params [Hash] input parameters
        # @option params [Integer] :application_assistance_year The year for which assistance is being calculated
        # @option params [FinancialAssistance::Applicant] :applicant The applicant object
        # @return [Dry::Monads::Result] The result of the calculation, either Success or Failure
        def call(params)
          params            = yield validate(params)
          total_net_income  = yield calculate_net_income(params)

          Success(total_net_income)
        end

        private

        # Validates the input parameters
        # @param params [Hash] input parameters
        # @return [Dry::Monads::Result] The result of the validation, either Success or Failure
        def validate(params)
          if params[:application_assistance_year].is_a?(Integer) && params[:applicant].is_a?(FinancialAssistance::Applicant)
            Success(params)
          else
            Failure(
              'Invalid input params. Expected application_assistance_year as Integer and applicant as FinancialAssistance::Applicant.'
            )
          end
        end

        # Calculates the net income for the given parameters
        # @param params [Hash] input parameters
        # @return [Dry::Monads::Result] The result of the calculation, either Success or Failure
        def calculate_net_income(params)
          @assistance_year = params[:application_assistance_year]
          @assistance_year_start = Date.new(@assistance_year)
          @assistance_year_end = @assistance_year_start.end_of_year

          total_annual_income = calculate_total_annual_income(params[:applicant])
          total_deductions = calculate_total_deductions(params[:applicant])

          Success(total_annual_income - total_deductions)
        end

        # Calculates the total annual income for the applicant
        # @param applicant [FinancialAssistance::Applicant] The applicant object
        # @return [BigDecimal] The total annual income
        def calculate_total_annual_income(applicant)
          return Success(BigDecimal('0')) unless applicant.incomes

          applicant.incomes.inject(BigDecimal('0')) do |total, income|
            total + eligible_earned_annual_income(income)
          end
        end

        # Calculates the total deductions for the applicant
        # @param applicant [FinancialAssistance::Applicant] The applicant object
        # @return [BigDecimal] The total deductions
        def calculate_total_deductions(applicant)
          return Success(BigDecimal('0')) unless applicant.deductions

          applicant.deductions.inject(BigDecimal('0')) do |total, deduction|
            total + eligible_earned_annual_income(deduction)
          end
        end

        # Calculates the eligible earned annual income for a given income
        # @param income [Income] The income object
        # @return [BigDecimal] The eligible earned annual income
        def eligible_earned_annual_income(income)
          income_end_date = calculate_end_date(income)
          income_start_date = calculate_start_date(income, income_end_date)
          return BigDecimal('0') unless income_for_current_year?(income_start_date)
          compute_annual_income(income, income_start_date, income_end_date)
        end

        # Computes the annual income for a given income
        # @param income [Income] The income object
        # @param income_start_date [Date] The start date of the income
        # @param income_end_date [Date] The end date of the income
        # @return [BigDecimal] The computed annual income
        def compute_annual_income(income, income_start_date, income_end_date)
          income_per_day = daily_employee_income(income.frequency_kind, income.amount)
          end_date_year = income_end_date.year
          start_date_year = income_start_date.year

          start_day_of_year = income_start_date.yday
          year_difference = end_date_year - start_date_year
          days_in_start_year = Date.gregorian_leap?(income.start_on.year) ? 366 : 365
          end_day_of_year = income_end_date.yday + (year_difference * days_in_start_year)

          ((end_day_of_year - start_day_of_year + 1) * income_per_day).round(2)
        end

        # Calculates the start date for a given income
        # @param income [Income] The income object
        # @param income_end_date [Date] The end date of the income
        # @return [Date] The start date of the income
        def calculate_start_date(income, income_end_date)
          if (@assistance_year_start..@assistance_year_end).cover?(income_end_date) && @assistance_year_start > income.start_on
            @assistance_year_start
          else
            income.start_on
          end
        end

        # Calculates the end date for a given income
        # @param income [Income] The income object
        # @return [Date] The end date of the income
        def calculate_end_date(income)
          return income.end_on if income.end_on.present? && (income.end_on <= @assistance_year_end)
          @assistance_year_end
        end

        # Checks if the income is for the current year
        # @param income_start_date [Date] The start date of the income
        # @return [Boolean] True if the income is for the current year, false otherwise
        def income_for_current_year?(income_start_date)
          (@assistance_year_start..@assistance_year_end).cover?(income_start_date)
        end

        # Calculates the daily employee income based on frequency and amount
        # @param employee_cost_frequency [String] The frequency of the employee cost
        # @param employee_cost [BigDecimal] The amount of the employee cost
        # @return [BigDecimal] The daily employee income
        def daily_employee_income(employee_cost_frequency, employee_cost)
          return BigDecimal('0') if employee_cost.blank?
          no_of_days = @assistance_year_end.yday
          annual_amnt =  case employee_cost_frequency
                         when 'weekly' then (employee_cost * 52)
                         when 'monthly' then (employee_cost * 12)
                         when 'yearly' then employee_cost
                         when 'biweekly' then (employee_cost * 26)
                         when 'quarterly' then (employee_cost * 4)
                         when 'daily' then (employee_cost * 5 * 52)
                         when 'half_yearly' then (employee_cost * 2)
                         else 0
                         end

          income_per_day = annual_amnt.to_f / no_of_days
          BigDecimal(income_per_day.to_s)
        end
      end
    end
  end
end
