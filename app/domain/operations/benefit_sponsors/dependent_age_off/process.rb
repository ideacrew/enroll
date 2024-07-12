# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'
module Operations
  module BenefitSponsors
    module DependentAgeOff
      # Operation triggers events to terminate enrollments with aged of dependents
      # This operation gets hit every 1st of and month and processes based on the yml settings to determine if the operations should be running annualy/monthly.
      class Process
        include Config::SiteConcern
        include EventSource::Command
        include Dry::Monads[:do, :result]

        def call(params)
          new_date, enrollment_query = params.values_at(:new_date, :enrollment_query)

          yield can_process_event(new_date)
          shop_logger = yield initialize_logger("shop")
          query_criteria = yield shop_query_criteria(enrollment_query)
          process_shop_dep_age_off(query_criteria, shop_logger, new_date)
        end

        private

        def can_process_event(new_date)
          if new_date != TimeKeeper.date_of_record.beginning_of_year && ::EnrollRegistry[:aca_shop_dependent_age_off].settings(:period).item == :annual
            Failure('Cannot process the request, because shop dependent age off is not set for end of every month')
          else
            Success('')
          end
        end

        def initialize_logger(market_kind)
          logger_file = Logger.new("#{Rails.root}/log/dependent_age_off_#{market_kind}_#{TimeKeeper.date_of_record.strftime('%Y_%m_%d')}.log")
          Success(logger_file)
        end

        def shop_query_criteria(enrollment_query)
          return Success(enrollment_query) unless enrollment_query.nil?

          # only interested in terminating previous year's enrollments
          Success(::HbxEnrollment.by_year(TimeKeeper.date_of_record.last_year.year).enrolled.shop_market.all_with_multiple_enrollment_members)
        end

        def process_shop_dep_age_off(enrollments, shop_logger, new_date) # rubocop:disable Metrics/CyclomaticComplexity
          failed_enrollments = []
          enrollments.no_timeout.each do |enrollment|
            next if enrollment.employer_profile&.is_fehb?
            payload = { enrollment_hbx_id: enrollment.hbx_id.to_s, new_date: new_date }

            if Rails.env.test?
              Operations::BenefitSponsors::DependentAgeOff::Terminate.new.call(**payload)
            else
              event = event('events.benefit_sponsors.non_congressional.dependent_age_off_termination.requested', attributes: payload).value!
              event.publish
              shop_logger.info "Published dependent_age_off_termination event for enrollment #{enrollment.hbx_id} at #{TimeKeeper.datetime_of_record}"
            end

            Success()
          rescue StandardError => e
            failed_enrollments << enrollment.hbx_id
            shop_logger.error "Unable to publish dependent_age_off_termination event for enrollment #{enrollment.hbx_id} due to #{e.message}"
          end

          if failed_enrollments.blank?
            Success("Successfully processed dependent age-off termination at #{TimeKeeper.datetime_of_record}")
          else
            Failure("Failed to process dependent age-off terminations for a subset of enrollments: #{failed_enrollments.join(', ')}")
          end
        end
      end
    end
  end
end
