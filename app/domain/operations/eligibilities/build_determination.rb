# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

# eligibility_items_requested = [
#   aptc_csr_credit: {
#     evidence_items: [:esi_evidence]
#   }
# ]

module Operations
  module Eligibilities
    # Build determination for subjects passed with effective date
    class BuildDetermination
      send(:include, Dry::Monads[:result, :do])

      # @param [Hash] opts Options to build determination
      # @option opts [Array<GlobalID>] :subjects required
      # @option opts [Array<Hash>] :eligibility_items_requested optional
      # @option opts [Date] :effective_date required
      # @return [Dry::Monad] result
      def call(params)
        values = yield validate(params)
        eligibility_items = yield get_eligibility_items(values)
        determination_hash =
          yield build_determination(eligibility_items, values)
        determination_entity = yield create_determination(determination_hash)

        Success(determination_entity)
      end

      private

      def validate(params)
        errors = []
        errors << 'subject ref missing' unless params[:subjects]
        errors << 'evidence ref missing' unless params[:effective_date]

        errors.empty? ? Success(params) : Failure(errors)
      end

      def get_eligibility_items(_values)
        eligibility_item_keys =
          EnrollRegistry[:'gid://enroll_app/Family'].setting(:eligibility_items)
                                                    .item

        eligibility_items =
          eligibility_item_keys.collect do |eligibility_item_key|
            next unless EnrollRegistry[eligibility_item_key].enabled?
            eligibility_item_result =
              Operations::EligibilityItems::Find.new.call(
                eligibility_item_key: eligibility_item_key
              )
            eligibility_item_result.success if eligibility_item_result.success?
          end.compact

        Success(eligibility_items)
      end

      def build_determination(eligibility_items, values)
        subjects =
          values[:subjects]
          .collect do |subject|
            subject_instance = GlobalID::Locator.locate(subject)

            person = subject_instance.person
            person_attributes =
              person.attributes.slice(
                'first_name',
                'last_name',
                'encrypted_ssn',
                'hbx_id'
              )
            person_attributes['person_id'] = person.id.to_s
            person_attributes['dob'] = person.dob

            subject_params = {
              is_primary: subject_instance.is_primary_applicant?,
              eligibility_states:
                build_eligibility_states(subject, eligibility_items, values)
            }

            Hash[
              subject.uri,
              subject_params
                .merge(person_attributes.symbolize_keys)
                .merge(
                  outstanding_verification_status: outstanding_verification_status_for_subject(subject_params)
                )
            ]
          end
          .reduce(:merge)

        determination = {
          effective_date: values[:effective_date],
          subjects: subjects
        }

        Success(
          determination.merge(
            outstanding_verification_status: outstanding_verification_status_for_determination(determination)
          )
        )
      end

      def outstanding_verification_status_for_subject(subject)
        enrolled = false
        eligibility_states = subject[:eligibility_states].values

        eligibility_states.each do |eligibility_state|
          eligibility_key = eligibility_state[:key]
          unless %w[
                   health_product_enrollment_status
                   dental_product_enrollment_status
                 ].include?(eligibility_key)
            next
          end
          enrolled = true if eligibility_state[:evidence_states].present?
        end

        return 'not_enrolled' unless enrolled
        if eligibility_states.all? do |eligibility_state|
             eligibility_state[:is_eligible]
           end
          return 'eligible'
        end
        if eligibility_states.any? do |eligibility_state|
             eligibility_state[:document_status] == 'Partially Uploaded'
           end
          return 'outstanding'
        end
        'pending'
      end

      def outstanding_verification_status_for_determination(determination)
        subjects = determination[:subjects].values
        subjects.reject! do |subject|
          subject[:outstanding_verification_status] == 'not_enrolled'
        end

        return 'eligible' if subjects.all? { |subject| subject[:outstanding_verification_status] == 'eligible' }
        return 'outstanding' if subjects.any? { |subject| subject[:outstanding_verification_status] == 'outstanding' }
        'pending'
      end

      def build_eligibility_states(subject, eligibility_items, values)
        eligibility_items
          .collect do |eligibility_item|
            unless values[:eligibility_items_requested].blank? ||
                   values[:eligibility_items_requested]&.key?(
                     eligibility_item.key.to_sym
                   )
              next
            end

            evidence_item_keys = []
            if values[:eligibility_items_requested]&.key?(
              eligibility_item.key.to_sym
            )
              evidence_item_keys =
                values[:eligibility_items_requested][
                  eligibility_item.key.to_sym
                ][
                  :evidence_items
                ]
            end

            eligibility_state =
              BuildEligibilityState.new.call(
                effective_date: values[:effective_date],
                subject: subject,
                eligibility_item: eligibility_item,
                evidence_item_keys: evidence_item_keys
              )
            if eligibility_state.success?
              Hash[eligibility_item.key.to_sym, eligibility_state.success]
            else
              Hash[eligibility_item.key.to_sym, {}]
            end
          end
          .compact
          .reduce(:merge)
      end

      def create_determination(determination_hash)
        ::Operations::Determinations::Create.new.call(determination_hash)
      end
    end
  end
end
