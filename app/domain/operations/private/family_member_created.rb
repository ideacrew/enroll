# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module Private
    # This class publishes a cv family payload on family member created events
    class FamilyMemberCreated
      include Dry::Monads[:result, :do]
      include EventSource::Command

      def call(params, headers)
        values = yield validate(params, headers)
        family = yield find_family(values)
        build_and_publish_cv_family(family, headers)
      end

      def validate(params, headers)
        return Failure("Family not found") if params.nil?
        return Failure("Created at not found") if headers.nil?
        Success(params)
      end

      def find_family(family_hash)
        family = Family.find(family_hash[:_id])
        return Success(family) if family.present?
        Failure("Family not found")
      end

      def build_and_publish_cv_family(family, headers)
        cv_family = build_cv_family(family)
        if cv_family.success?
          publish_families_created_or_updated(family, cv_family.success, headers)
        else
          handle_cv_family_failure(family, cv_family)
        end
      rescue StandardError => e
        Rails.logger.error { "Error building and publishing cv family for family member: #{family&.primary_person&.hbx_id} due to: #{e.message}" }
        Failure("Error building and publishing cv family for family member: #{family&.primary_person&.hbx_id} due to: #{e.message}")
      end

      def build_cv_family(family)
        Operations::Transformers::FamilyTo::Cv3Family.new.call(family, true)
      end

      def handle_cv_family_failure(family, cv_family)
        Rails.logger.info { "Failed to build cv family for family member: #{family&.primary_person&.hbx_id} due to: #{cv_family.failure}" }
        Failure("Failed to build cv family for family member: #{family&.primary_person&.hbx_id} due to: #{cv_family.failure}")
      end

      def publish_families_created_or_updated(family, cv_family, headers)
        event('events.families.created_or_updated', attributes: {after_save_cv_family: cv_family}, headers: headers)&.success&.publish
        Rails.logger.info { "Successfully published 'events.families.created_or_updated' for family member with hbx_id: #{family&.primary_person&.hbx_id}" }
        Success("Successfully published 'events.families.created_or_updated' for family member with hbx_id: #{family&.primary_person&.hbx_id}")
      end
    end
  end
end
