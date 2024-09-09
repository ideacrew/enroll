# frozen_string_literal: true

module Operations
  module Migrations
    module Applications
      module BenchmarkPremiums
        # Class for populating benchmark premiums for the input application
        class Populate

          # { application_id: application_id }
          def call(params)
            @logger             = yield initialize_logger
            application_id      = yield validate_params(params)
            application         = yield find_application(application_id)
            benchmark_premiums  = yield fetch_benchmark_premiums(application)
            result              = yield populate_benchmark_premiums(application, benchmark_premiums)

            Success(result)
          end

          private

          def initialize_logger
            Success(
              Logger.new(
                "#{Rails.root}/log/benchmark_premiums_migration_populator_#{TimeKeeper.date_of_record.strftime('%Y_%m_%d')}.log"
              )
            )
          end

          def validate_params(params)
            @logger.info "Validating input params: #{params}." unless Rails.env.test?

            if params[:application_id].nil?
              failure_message = "Invalid input application id: #{params[:application_id]}."
              @logger.error "-- FAILED -- app_id: #{params[:application_id]}. Message: #{failure_message}" unless Rails.env.test?
              Failure()
            else
              Success(application_id)
            end
          end

          def find_application(application_id)
            application = ::FinancialAssistance::Application.only(
              :_id,
              :aasm_state,
              :effective_date,
              :'applicants.person_hbx_id',
              :'applicants.is_primary_applicant',
              :'applicants.addresses'
            ).where(_id: application_id).first

            if application.present?
              Success(application)
            else
              failure_message = "Application not found for id: #{application_id}"
              @logger.error "-- FAILED -- app_id: #{application_id}. Message: #{failure_message}" unless Rails.env.test?
              Failure(failure_message)
            end
          end

          def fetch_benchmark_premiums(application)
            benchmark_member_premiums = ::Operations::Migrations::Applications::BenchmarkPremiums::FetchProducts.new.call(
              application: application,
              effective_date: application.effective_date
            )

            if benchmark_member_premiums.success?
              benchmark_member_premiums
            else
              failure_message = "Failed to fetch benchmark premiums for application: #{application._id} - #{benchmark_member_premiums.failure}"
              @logger.error "-- FAILED -- app_id: #{application._id}. Message: #{failure_message}" unless Rails.env.test?
              Failure(failure_message)
            end
          end

          # 1. Need to verify if set updates the updated_at field
          # 2. Need to verify if set persists the changes to the database or just in memory
          def populate_benchmark_premiums(application, benchmark_premiums)
            application.applicants.each do |applicant|
              applicant.set(
                benchmark_premiums: benchmark_premiums,
                updated_at: DateTime.now.utc
              )
            end
          end
        end
      end
    end
  end
end
