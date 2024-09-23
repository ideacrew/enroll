# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module EligibilityItems
    # Find eligibility item from resource registry
    class Find
      include Dry::Monads[:do, :result]

      # @param [Hash] opts Options to find eligibility item from Resource Registry

      # @option opts [String] :eligibility_item_key required
      # @return [Dry::Monad] result
      def call(params)
        values = yield validate(params)
        eligibility_item_params = yield find_eligibility_item(values)
        eligibility_item =
          yield create_eligibility_item(eligibility_item_params)

        Success(eligibility_item)
      end

      private

      def validate(params)
        errors = []
        errors << 'eligibility_item_key missing' unless params[:eligibility_item_key]

        errors.empty? ? Success(params) : Failure(errors)
      end

      def find_eligibility_item(values)
        evidence_item_keys =
          EnrollRegistry[values[:eligibility_item_key]].setting(:evidence_items)
                                                       .item

        evidence_items =
          evidence_item_keys.collect do |evidence_item_key|
            evidence_feature = EnrollRegistry[evidence_item_key]
            next unless evidence_feature.enabled?
            get_evidence_item(evidence_feature)
          end.compact
        Success(
          { key: values[:eligibility_item_key], evidence_items: evidence_items }
        )
      end

      def get_evidence_item(evidence_feature)
        {
          key: evidence_feature.key.to_sym,
          subject_ref: URI(evidence_feature.setting(:subject_ref).item),
          evidence_ref: URI(evidence_feature.setting(:evidence_ref).item)
        }
      end

      def create_eligibility_item(eligibility_item_params)
        Operations::EligibilityItems::Create.new.call(eligibility_item_params)
      end
    end
  end
end
