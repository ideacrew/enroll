# frozen_string_literal: true

require "dry/monads"
require "dry/monads/do"

# Instructions: Run this script in rails console to migrate eligibilities
# grouped_records =
#   ::Eligibilities::Osse::Eligibility.collection.aggregate(
#     [
#       {
#         "$match" => {
#           eligibility_type:
#             /BenefitSponsors::BenefitSponsorships::BenefitSponsorship/i
#         }
#       },
#       { "$group": { _id: "$subject.key", records: { "$push": "$$ROOT" } } }
#     ]
#   )

# grouped_records.each do |entry|
#   subject = GlobalID::Locator.locate(entry["_id"])
#   eligibilities =
#     entry["records"].sort_by { |record| record["created_at"].to_i }
#   ids = eligibilities.collect { |r| r["_id"] }
#   eligibility_records = ::Eligibilities::Osse::Eligibility.where(:_id.in => ids)

#   result =
#     Operations::Eligible::MigrateEligibility.new.call(
#       eligibility_key: :shop_osse_eligibility,
#       current_eligibilities: eligibility_records
#     )
# end

module Operations
  module Eligible
    # Operation to support eligibility creation
    class MigrateEligibility
      send(:include, Dry::Monads[:result, :do])

      # @param [Hash] opts Options to build eligibility
      # @option opts [<String>]   :eligibility_key required
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
        errors << "eligibility key missing" unless params[:eligibility_key]
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

      def migrate(subject, values)
        values[:current_eligibilities].each do |eligibility|
          next unless eligibility.evidences.present?

          migrate_eligibility(subject, values, eligibility)
        end

        Success(true)
      end

      def migrate_eligibility(subject, values, eligibility)
        logger(
          "initialize_eligibility_is_satisfied_as_false for #{subject.to_global_id.to_s}"
        ) { initialize_eligibility(subject, values, eligibility) }

        eligibility.evidences.each do |evidence|
          effective_date = eligibility.start_on
          effective_date = evidence.updated_at unless evidence.is_satisfied
          logger(
            "update_eligibility_is_satisfied_as_#{evidence.is_satisfied} for #{subject.to_global_id.to_s}"
          ) do
            migrate_record(
              values,
              {
                subject: subject.to_global_id,
                evidence_key: evidence_key_for(values[:eligibility_key]),
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
          eligibility_operation_for(values[:eligibility_key]).new.call(
            eligibility_options
          )

        if result.success?
          eligibility = result.success
          eligibility.tap do |eligibility|
            reset_timestamps(eligibility)
            eligibility.evidences.last.tap do |evidence|
              reset_timestamps(evidence)
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
        if state_history
          record.updated_at = state_history.updated_at
          if record.created_at > record.created_at
            record.created_at = state_history.created_at
          end
        end
      end

      def initialize_eligibility(subject, values, eligibility)
        migrate_record(
          values,
          {
            subject: subject.to_global_id,
            evidence_key: evidence_key_for(values[:eligibility_key]),
            evidence_value: "false",
            effective_date: eligibility.start_on,
            timestamps: {
              created_at: eligibility.created_at.to_datetime,
              modified_at: eligibility.created_at.to_datetime
            }
          }
        )
      end

      def eligibility_operation_for(eligibility_key)
        if eligibility_key == :shop_osse_eligibility
          ::BenefitSponsors::Operations::BenefitSponsorships::ShopOsseEligibilities::CreateShopOsseEligibility
        else
          ::Operations::IvlOsseEligibilities::CreateIvlOsseEligibility
        end
      end

      def evidence_key_for(eligibility_key)
        if eligibility_key == :shop_osse_eligibility
          :shop_osse_evidence
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
    end
  end
end
