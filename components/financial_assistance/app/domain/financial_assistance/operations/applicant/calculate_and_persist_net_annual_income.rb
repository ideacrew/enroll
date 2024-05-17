# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module FinancialAssistance
  module Operations
    module Applicant
      #This class calculated net annual income for a applicant
      # Net Annual Income = Total Incomes - Total Deductions
      class CalculateAndPersistNetAnnualIncome
        include Dry::Monads[:do, :result]

        # @param [application assistance year, applicant object] input
        #
        # @return [applicant]
        def call(params)
          params = yield validate(params)
          total_net_income = yield calculate_net_income(params)
          result = yield persist(params[:applicant], total_net_income)

          Success(result)
        end

        private

        def validate(params)
          if params[:application_assistance_year].present? && params[:applicant].present? && params[:applicant].is_a?(FinancialAssistance::Applicant)
            Success(params)
          else
            Failure("Invalid Params")
          end
        end

        def calculate_net_income(params)
          @assistance_year = params[:application_assistance_year]
          @assistance_year_start = Date.new(@assistance_year)
          @assistance_year_end = @assistance_year_start.end_of_year

          total_annual_income = calculate_total_annual_income(params[:applicant])
          total_deductions = calculate_total_deductions(params[:applicant])

          Success(total_annual_income - total_deductions)
        end

        def calculate_total_annual_income(applicant)
          return Success(BigDecimal('0')) unless applicant.incomes

          applicant.incomes.inject(BigDecimal('0')) do |total, income|
            total + eligible_earned_annual_income(income)
          end
        end

        def calculate_total_deductions(applicant)
          return Success(BigDecimal('0')) unless applicant.deductions

          applicant.deductions.inject(BigDecimal('0')) do |total, deduction|
            total + eligible_earned_annual_income(deduction)
          end
        end

        def eligible_earned_annual_income(income)
          income_end_date = calculate_end_date(income)
          income_start_date = calculate_start_date(income, income_end_date)
          return BigDecimal('0') unless income_for_current_year?(income_start_date)
          compute_annual_income(income, income_start_date, income_end_date)
        end

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

        def calculate_start_date(income, income_end_date)
          if (@assistance_year_start..@assistance_year_end).cover?(income_end_date) && @assistance_year_start > income.start_on
            @assistance_year_start
          else
            income.start_on
          end
        end

        def calculate_end_date(income)
          return income.end_on if income.end_on.present? && (income.end_on <= @assistance_year_end)
          @assistance_year_end
        end

        def income_for_current_year?(income_start_date)
          (@assistance_year_start..@assistance_year_end).cover?(income_start_date)
        end

        def persist(applicant, total_net_income)
          applicant.update_attributes(net_annual_income: total_net_income) unless applicant.net_annual_income&.to_d == total_net_income&.to_d
          Success(applicant)
        end

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
