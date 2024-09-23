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
      include Dry::Monads[:do, :result]

      # @param [Hash] opts Options to build determination
      # @option opts [Array<GlobalID>] :subjects required
      # @option opts [Array<Hash>] :eligibility_items_requested optional
      # @option opts [Date] :effective_date required
      # @return [Dry::Monad] result
      def call(params)
        values = yield validate(params)
        eligibility_items = yield get_eligibility_items(values)
        determination_hash = yield build_determination(eligibility_items, values)
        determination_entity = yield create_determination(determination_hash)

        Success(determination_entity)
      end

      private

      def validate(params)
        errors = []
        errors << 'subject ref missing' unless params[:subjects]
        errors << 'effective_date ref missing' unless params[:effective_date]
        errors << 'family ref missing' unless params[:family]

        errors.empty? ? Success(params) : Failure(errors)
      end

      def get_eligibility_items(_values)
        eligibility_item_keys = EnrollRegistry[:'gid://enroll_app/Family'].setting(:eligibility_items).item

        eligibility_items =
          eligibility_item_keys.collect do |eligibility_item_key|
            next unless EnrollRegistry[eligibility_item_key].enabled?
            eligibility_item_result = Operations::EligibilityItems::Find.new.call(eligibility_item_key: eligibility_item_key)
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
            person_attributes = person.attributes.slice('first_name', 'last_name', 'encrypted_ssn', 'hbx_id')
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
                  outstanding_verification_status:
                    outstanding_verification_status_for_subject(
                      subject_params
                    )
                )
            ]
          end
          .reduce(:merge)

        grants = build_aptc_grants(values[:family], values[:effective_date]).success

        determination = {
          effective_date: TimeKeeper.date_of_record, # Since this is only being used for eligibility determination effective date
          subjects: subjects,
          grants: grants
        }

        Success(
          determination.merge(
            outstanding_verification_status: outstanding_verification_status_for_determination(determination),
            outstanding_verification_earliest_due_date: outstanding_verification_due_on_for_determination(determination),
            outstanding_verification_document_status: outstanding_verification_document_status_for_determination(determination)
          )
        )
      end

      def build_aptc_grants(family, effective_date)
        Operations::Eligibilities::BuildGrant.new.call(family: family, type: 'AdvancePremiumAdjustmentGrant', effective_date: effective_date)
      end

      # rubocop:disable Metrics/CyclomaticComplexity
      def outstanding_verification_status_for_subject(subject)
        enrolled = false
        subject[:eligibility_states].each do |eligibility_key, eligibility_state|
          next unless %i[health_product_enrollment_status dental_product_enrollment_status].include?(eligibility_key)
          enrolled = true if eligibility_state[:evidence_states].present?
        end

        eligibility_states = subject[:eligibility_states].slice(:aptc_csr_credit, :aca_individual_market_eligibility).values

        return 'not_enrolled' unless enrolled

        return 'eligible' if eligibility_states.all? { |eligibility_state| eligibility_state[:is_eligible] }
        return 'outstanding' if eligibility_states.any? { |eligibility_state| eligibility_state[:evidence_states].present? && !eligibility_state[:is_eligible]}
        return 'pending' if eligibility_states.all? { |eligibility_state| eligibility_state[:is_eligible] || eligibility_state[:evidence_states].blank? }
        return 'outstanding' if eligibility_states.any? { |eligibility_state| !eligibility_state[:is_eligible]}

        'pending'
      end
      # rubocop:enable Metrics/CyclomaticComplexity

      def outstanding_verification_status_for_determination(determination)
        subjects = determination[:subjects].values
        subjects.reject! do |subject|
          subject[:outstanding_verification_status] == 'not_enrolled'
        end

        return 'not_enrolled' if subjects.blank?
        if subjects.all? do |subject|
             subject[:outstanding_verification_status] == 'eligible'
           end
          return 'eligible'
        end
        if subjects.any? do |subject|
             subject[:outstanding_verification_status] == 'outstanding'
           end
          return 'outstanding'
        end
        'pending'
      end

      def outstanding_verification_due_on_for_determination(determination)
        subjects = determination[:subjects].values
        subjects.reject! do |subject|
          subject[:outstanding_verification_status] == 'not_enrolled'
        end
        subjects.reduce([]) do |memo, subject|
          aptc_csr_credit = subject[:eligibility_states][:aptc_csr_credit]
          aca_individual_market_eligibility = subject[:eligibility_states][:aca_individual_market_eligibility]
          memo << aptc_csr_credit[:earliest_due_date] if aptc_csr_credit && aptc_csr_credit[:earliest_due_date]
          memo << aca_individual_market_eligibility[:earliest_due_date] if aca_individual_market_eligibility && aca_individual_market_eligibility[:earliest_due_date]
          memo
        end.compact.min
      end

      def eligibility_documents_uploaded_status(determination)
        subjects = determination[:subjects].values
        subjects.reject! do |subject|
          subject[:outstanding_verification_status] == 'not_enrolled'
        end
        subjects.reduce([]) do |memo, subject|
          aptc_csr_credit = subject[:eligibility_states][:aptc_csr_credit]
          aca_individual_market_eligibility = subject[:eligibility_states][:aca_individual_market_eligibility]
          memo << aptc_csr_credit[:document_status] if aptc_csr_credit && aptc_csr_credit[:document_status]
          memo << aca_individual_market_eligibility[:document_status] if aca_individual_market_eligibility && aca_individual_market_eligibility[:document_status]
          memo
        end.compact
      end

      def outstanding_verification_document_status_for_determination(determination)
        document_states = eligibility_documents_uploaded_status(determination)
        active_document_states = document_states.reject{|status| status == 'NA'}
        return 'NA' if active_document_states.empty?
        return active_document_states.first if active_document_states.uniq.count == 1
        'Partially Uploaded'
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
