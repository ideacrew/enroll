# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module Individual
    # Determine verifications
    class DetermineVerifications
      send(:include, Dry::Monads[:result, :do])

      def call(params)
        consumer_role_id = yield validate(params[:id])
        determine(consumer_role_id)
      end

      private

      def validate(id)
        return Failure('Id should not be blank') unless id
        Success(id)
      end

      def determine(id)
        consumer_role = ConsumerRole.find(id)
        person = consumer_role.person

        return Failure('person not found') if person.blank?

        attrs = OpenStruct.new({
                                 :determined_at => Time.now,
                                 :vlp_authority => 'hbx'
                               })

        consumer_role.revert!(attrs)
        consumer_role.coverage_purchased_no_residency!(attrs)
        consumer_role.trigger_residency! if can_trigger_residency?(person)

        Success()
      rescue StandardError => e
        Failure("Error - #{e}")
      end

      def can_trigger_residency?(person)
        EnrollRegistry.feature_enabled?(:location_residency_verification_type) &&
          person.age_on(TimeKeeper.date_of_record) > 18 &&
          requires_residency?(person)
      end

      def requires_residency?(person)
        residency_type = person.verification_types.active.where(applied_roles: "consumer_role", type_name: ::ConsumerRole::LOCATION_RESIDENCY).first

        !(person.is_homeless || person.is_temporarily_out_of_state) ||
          (person.is_consumer_role_active? && residency_type&.validation_status == 'unverified')
      end
    end
  end
end
