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
    class BuildFamilyDetermination
      send(:include, Dry::Monads[:result, :do])

      # @param [Hash] opts Options to build determination
      # @option opts [Family] :family required
      # @option opts [Date] :effective_date required
      # @return [Dry::Monad] result
      def call(params)
        values = yield validate(params)
        determination_entity = yield build_determination(values)
        determination = yield persist(values, determination_entity)

        Success(determination)
      end

      private

      def validate(params)
        errors = []
        errors << 'family missing' unless params[:family]
        errors << 'effective date missing' unless params[:effective_date]

        errors.empty? ? Success(params) : Failure(errors)
      end

      def build_determination(values)
        subjects = values[:family].family_members.map(&:to_global_id)

        family = values[:family]
        primary_person = family&.primary_applicant&.person
        is_any_member_applying_for_coverage = family.family_members.select(&:is_active).any?(&:is_applying_coverage)
        if (is_any_member_applying_for_coverage && primary_person.consumer_role.present?) || values[:is_migrating]
          BuildDetermination.new.call(subjects: subjects, effective_date: values[:effective_date], family: family)
        else
          Failure("Person don't have consumer role or is not applying for coverage")
        end
      end

      def persist(values, determination_entity)
        family = values[:family]
        attributes = determination_entity.sanitize_attributes
        model_attributes = transform(attributes)
        determination = ::Eligibilities::Determination.new(model_attributes)
        family.eligibility_determination = determination
        family.save

        Success(determination)
      end

      def relations
        {
          subjects: :gid,
          eligibility_states: :eligibility_item_key,
          evidence_states: :evidence_item_key
        }
      end

      def transform(values)
        values.reduce({}) do |data, (key, value)|
          data[key] = if relations.key?(key) && value.is_a?(Hash)
                        flatten_keys(value, relations[key])
                      elsif value.is_a?(URI::GID)
                        value.to_s
                      else
                        value
                      end
          data
        end
      end

      def flatten_keys(input, attribute_name)
        input.reduce([]) do |records, (key, value)|
          records << transform(value.merge(Hash[attribute_name, key]))
        end
      end
    end
  end
end
