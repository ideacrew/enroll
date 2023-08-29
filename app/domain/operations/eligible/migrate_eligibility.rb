# frozen_string_literal: true

require "dry/monads"
require "dry/monads/do"

module Operations
  module Eligible
    # Operation to support eligibility creation
    class MigrateEligibility
      send(:include, Dry::Monads[:result, :do])

      # @param [Hash] opts Options to build eligibility
      # @option opts [<String>]   :eligibility_type required
      # @option opts [<Array>]   :current_eligibilities required
      # @return [Dry::Monad] result
      def call(params)
        values = yield validate(params)
        subject = yield find_subject(values)
        result = yield migrate(subject, values)

        Success(result)
      end

      private

      def validate(params)
        errors = []
        errors << "eligibility key missing" unless params[:eligibility_type]
        unless params[:current_eligibilities].present?
          errors << "current eligibilities missing"
        end

        errors.empty? ? Success(params) : Failure(errors)
      end

      def find_subject(values)
        subject =
          GlobalID::Locator.locate(
            values[:current_eligibilities].first.subject.key
          )

        Success(subject)
      end

      def add_renewal_eligibilities(values)
        current_year = Date.today.year
        prev_year = current_year - 1

        eligibility_years =
          values[:current_eligibilities].collect(&:start_on).map(&:year).uniq
        return unless eligibility_years == [prev_year]

        last_eligibility = values[:current_eligibilities].max_by(&:updated_at)
        return if last_eligibility.end_on.present?
        renewal_eligibility =
          ::Eligibilities::Osse::Eligibility.new(
            renewal_eligibility_params(last_eligibility)
          )
        values[:current_eligibilities] << renewal_eligibility
      end

      def migrate(subject, values)
        add_renewal_eligibilities(values)
        values[:current_eligibilities].compact.each do |eligibility|
          next unless eligibility.evidences.present?
          migrate_eligibility(subject, values, eligibility)
        end

        Success(true)
      end

      def migrate_eligibility(subject, values, eligibility)
        unless subject.reload.eligibility_on(eligibility.start_on)
          logger(
            "initialize_eligibility_is_satisfied_as_false for #{subject.to_global_id}"
          ) { initialize_eligibility(subject, values, eligibility) }
        end

        eligibility
          .evidences
          .sort_by(&:updated_at)
          .each do |evidence|
            effective_date = eligibility.start_on.to_date
            effective_date =
              evidence.updated_at.to_date unless evidence.is_satisfied
            logger(
              "update_eligibility_is_satisfied_as_#{evidence.is_satisfied} for #{subject.to_global_id}"
            ) do
              migrate_record(
                values,
                {
                  subject: subject.to_global_id,
                  evidence_key: evidence_key_for(values[:eligibility_type]),
                  evidence_value: evidence.is_satisfied.to_s,
                  effective_date: effective_date,
                  timestamps: {
                    created_at: evidence.created_at.to_datetime,
                    modified_at: evidence.updated_at.to_datetime
                  }
                }
              )
            end
          end
      end

      def migrate_record(values, eligibility_options)
        result =
          eligibility_operation_for(values[:eligibility_type]).new.call(
            eligibility_options
          )

        if result.success?
          eligibility = result.success
          eligibility.tap do |eligibility_instance|
            reset_timestamps(eligibility_instance)
            eligibility_instance.evidences.last.tap do |evidence_instance|
              reset_timestamps(evidence_instance)
            end
          end
          unless eligibility.save
            print_error "unable to reset timestamps #{result.failure}"
          end
        end
        result
      end

      def reset_timestamps(record)
        state_history = record.state_histories.last
        return unless state_history
        record.updated_at = state_history.updated_at
        record.created_at = state_history.created_at if record.created_at >
          record.updated_at
      end

      def initialize_eligibility(subject, values, eligibility)
        updated_timestamps = eligibility.evidences.map(&:updated_at)
        calendar_years = updated_timestamps.map(&:year).uniq

        results =
          calendar_years.collect do |calendar_year|
            earliest_timestamp =
              updated_timestamps.detect do |timestamp|
                timestamp.year == calendar_year
              end

            migrate_record(
              values,
              {
                subject: subject.to_global_id,
                evidence_key: evidence_key_for(values[:eligibility_type]),
                evidence_value: "false",
                effective_date: Date.new(calendar_year, 1, 1),
                timestamps: {
                  created_at: earliest_timestamp.to_datetime,
                  modified_at: earliest_timestamp.to_datetime
                }
              }
            )
          end

        if results.all?(&:success?)
          Success(results)
        else
          Failure(results.detect(&:failure?).failure)
        end
      end

      def eligibility_operation_for(eligibility_type)
        case eligibility_type
        when "BenefitSponsors::BenefitSponsorships::BenefitSponsorship"
          ::BenefitSponsors::Operations::BenefitSponsorships::ShopOsseEligibilities::CreateShopOsseEligibility
        when "SponsoredBenefits::BenefitSponsorships::BenefitSponsorship"
          ::SponsoredBenefits::Operations::BenefitSponsorships::BqtOsseEligibilities::CreateBqtOsseEligibility
        else
          ::Operations::IvlOsseEligibilities::CreateIvlOsseEligibility
        end
      end

      def evidence_key_for(eligibility_type)
        case eligibility_type
        when "BenefitSponsors::BenefitSponsorships::BenefitSponsorship"
          :shop_osse_evidence
        when "SponsoredBenefits::BenefitSponsorships::BenefitSponsorship"
          :bqt_osse_evidence
        else
          :ivl_osse_evidence
        end
      end

      def logger(action)
        print_message "started processing #{action}"
        result = yield

        if result.success?
          print_message "completed processing #{action}"
          result.success
        else
          print_error "failed processing #{action}"
          print_error result.failure
          result.failure
        end
      end

      def print_message(message)
        Rails.logger.info message
        puts message
      end

      def print_error(error)
        Rails.logger.error error
        puts error
      end

      def renewal_eligibility_params(last_eligibility)
        {
          "start_on" => last_eligibility.start_on.next_year.beginning_of_year,
          "eligibility_id" => last_eligibility.eligibility_id,
          "eligibility_type" => last_eligibility.eligibility_type,
          "updated_at" => DateTime.now,
          "created_at" => DateTime.now,
          "subject" => {
            "title" => "Subject for Osse Subsidy",
            "key" => last_eligibility.subject.key,
            "klass" => last_eligibility.eligibility_type,
            "updated_at" => DateTime.now,
            "created_at" => DateTime.now
          },
          "evidences" => [
            {
              "key" => :osse_subsidy,
              "title" => "Evidence for Osse Subsidy",
              "is_satisfied" => true,
              "updated_at" => DateTime.now,
              "created_at" => DateTime.now
            }
          ]
        }
      end
    end
  end
end
