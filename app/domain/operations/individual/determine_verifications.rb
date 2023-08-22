# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module Individual
    # Determine verifications
    class DetermineVerifications
      include Dry::Monads[:result, :do]

      def call(params)
        consumer_role_id = yield validate(params[:id])
        determine(consumer_role_id, params)
      end

      private

      def validate(id)
        return Failure('Id should not be blank') unless id
        Success(id)
      end

      def determine(id, params)
        consumer_role = ConsumerRole.find(id)
        person = consumer_role.person

        return Failure('person not found') if person.blank?
        return Failure('person not applying for coverage') unless person.is_applying_coverage

        if params[:skip_rr_config_and_active_enrollment_check] || can_update_consumer_role?(person)
          update_consumer_role(consumer_role, person)
        else
          Failure("ConsumerRole with person_hbx_id: #{person.hbx_id} is not enrolled to trigger hub calls")
        end
      rescue StandardError => e
        Failure("Error - #{e}")
      end

      def can_update_consumer_role?(person)
        EnrollRegistry.feature_enabled?(:trigger_verifications_before_enrollment_purchase) ||
          person.families.any? {|f| f.person_has_an_active_enrollment?(person) }
      end

      def update_consumer_role(consumer_role, person)
        attrs = OpenStruct.new({:determined_at => Time.now, :vlp_authority => 'hbx'})

        consumer_role.revert!(attrs)
        add_verification_type_history(consumer_role)
        consumer_role.coverage_purchased_no_residency!(attrs)
        trigger_residency(consumer_role) if can_trigger_residency?(person)
        consumer_role.person.save!
        Success("Successfully triggered Hub Calls for ConsumerRole with person_hbx_id: #{person.hbx_id}")
      end

      def add_verification_type_history(consumer_role)
        consumer_role.verification_types.where(:type_name.in => ["Citizenship", "Immigration status", "Social Security Number"]).each do |vt|
          vt.add_type_history_element(action: "Hub Request", modifier: "System", update_reason: "#{vt.type_name} Requested due to person update for applying coverage")
        end
      end

      def trigger_residency(consumer_role)
        vt = consumer_role.verification_types.where(:type_name.in => ::VerificationType::LOCATION_RESIDENCY).first
        add_verification_type_history(vt)
        vt.add_type_history_element(action: "Hub Request", modifier: "System", update_reason: "#{vt.type_name} Requested due to person update for applying coverage")
        consumer_role.trigger_residency!
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
