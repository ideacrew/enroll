# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module Private
    # This class publishes a cv3 family payload on family member created events
    class FamilyMemberCreated
      include Dry::Monads[:result, :do]
      include EventSource::Command

      def call(family_member)
        values = yield validate(family_member)
        build_and_publish_cv3_family(values)
      end

      def validate(family_member)
        return Failure("family member not found") if family_member.nil?
        Success(family_member)
      end

      def build_and_publish_cv3_family(family_member)
        headers = {after_save_updated_at: family_member.updated_at}
        family = family_member&.family
        return Failure("Family not found for family member: #{family_member&.person&.hbx_id}") unless family.present?
        cv3_family = build_cv3_family(family)
        if cv3_family.success?
          publish_families_created_or_updated(family_member, cv3_family.success, headers)
        else
          handle_cv3_family_failure(family_member, cv3_family)
        end
      rescue StandardError => e
        Rails.logger.error { "Error building and publishing cv3 family for family member: #{family_member&.person&.hbx_id} due to #{e.message}" }
        Failure("Error building and publishing cv3 family for family member: #{family_member&.person&.hbx_id} due to #{e.message}")
      end

      def build_cv3_family(family)
        Operations::Transformers::FamilyTo::Cv3Family.new.call(family)
      end

      def handle_cv3_family_failure(family_member, cv3_family)
        Rails.logger.info { "Failed to build cv3 family for family member: #{family_member&.person&.hbx_id} due to #{cv3_family.failure}" }
        Failure("Failed to build cv3 family for family member: #{family_member&.person&.hbx_id} due to #{cv3_family.failure}")
      end

      def publish_families_created_or_updated(family_member, cv3_family, headers)
        event('events.families.created_or_updated', attributes: {after_save_version: cv3_family}, headers: headers)&.success&.publish
        Rails.logger.info { "Successfully published 'events.families.created_or_updated' for family member with hbx_id: #{family_member&.person&.hbx_id}" }
        Success(family_member)
      end
    end
  end
end
