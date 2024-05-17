# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module BenefitMarkets
  module Operations
    module ContributionModels

      class Assign
        # include Dry::Monads::Do.for(:call)
        include Dry::Monads[:do, :result]

        # Executes the assignment process for a Benefit Sponsor Catalog.
        # This method takes a hash of parameters, performs a series of operations
        # to find, filter, match, and assign criteria, and then returns the updated product package values.
        #
        # @param params [Hash] A hash containing :product_package_values and :enrollment_eligibility.
        #   - :product_package_values [Hash] The current product package values.
        #   - :enrollment_eligibility [EnrollmentEligibility] The enrollment eligibility criteria.
        #
        # @return [Dry::Monads::Result] A Success or Failure monad.
        #   - Success: Contains a hash with the updated product package values.
        #   - Failure: Contains an error message.
        def call(params)
          product_package_values, enrollment_eligibility = params.values_at(:product_package_values, :enrollment_eligibility)

          criteria               = yield find_criteria(enrollment_eligibility)
          filtered_criteria      = yield filter_criteria(criteria, product_package_values[:contribution_models])
          matched_criterion      = yield match_criterion(filtered_criteria, enrollment_eligibility)
          product_package_values = yield assign(product_package_values, matched_criterion, enrollment_eligibility)

          Success({product_package_values: product_package_values })
        end

        private

        def find_criteria(enrollment_eligibility)
          namespace = namespace_for(enrollment_eligibility.market_kind, enrollment_eligibility.effective_date.year)
          contribution_model_criteria = EnrollRegistry.features_by_namespace(namespace).collect do |feature_key|
            EnrollRegistry[[namespace, feature_key.to_s].join('.')]
          end

          Success(contribution_model_criteria)
        end

        def filter_criteria(criteria, contribution_models)
          contribution_keys = contribution_models.map(&:key)
          filtered_criteria = criteria.select{|criterion| contribution_keys.include?(criterion.setting(:contribution_model_key).item) }
          Success(filtered_criteria)
        end

        def match_criterion(criteria, enrollment_eligibility)
          if criteria.size > 1
            sorted_criteria = criteria.sort_by{|ele| ele.setting(:order).item}
            criterion       = sorted_criteria.detect {|criterion| criterion_matches?(criterion, enrollment_eligibility) }
            criterion       = criteria.detect {|criterion| criterion.setting(:default).item } if criterion.blank?
          else
            criterion = criteria.first
          end

          Success(criterion)
        end

        # TODO: hard coded contribution model key for OSSE for now
        def assign(product_package_values, matched_criterion, enrollment_eligibility)
          criterion_contribution_key =
            if enrollment_eligibility.employer_contribution_minimum_relaxed?
              :zero_percent_sponsor_fixed_percent_contribution_model
            else
              matched_criterion.setting(:contribution_model_key).item
            end

          product_package_values[:assigned_contribution_model] = product_package_values[:contribution_models].detect do |contribution_model|
            contribution_model.key == criterion_contribution_key
          end

          Success(product_package_values)
        end

        def namespace_for(market_kind, calender_year)
          "enroll_app.#{market_kind}_market.benefit_market_catalog.catalog_#{calender_year}.contribution_model_criteria"
        end

        def criterion_matches?(criterion, enrollment_eligibility)
          criterion_application_kind = criterion.setting(:benefit_application_kind).item

          (criterion_application_kind == enrollment_eligibility.benefit_application_kind) && criterion.setting(:effective_period).item.cover?(enrollment_eligibility.effective_date)
        end
      end
    end
  end
end
