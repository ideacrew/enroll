# frozen_string_literal: true

module CrmGateway
  # Module for keeping extra family methods related to crm gateway
  module FamilyConcern
    extend ActiveSupport::Concern
    included do
      after_save :trigger_async_publish
    end

    def trigger_async_publish
      return unless EnrollRegistry.feature_enabled?(:crm_update_family_save)
      CrmWorker.perform_async(self.id.to_s, self.class.to_s, :trigger_crm_family_update_publish)
    end

    def trigger_crm_family_update_publish
      return unless EnrollRegistry.feature_enabled?(:crm_update_family_save)
      puts("Triggering CRM family update publish for family with mongo id #{self.id}")
      result = ::Operations::Families::SugarCrm::PublishFamily.new.call(self)
      # Update column directly without callbacks
      if result.success?
        if EnrollRegistry.feature_enabled?(:check_for_crm_updates)
          self.set(crm_notifiction_needed: false)
          self.family_members.each do |fm|
            fm.person&.set(crm_notifiction_needed: false)
          end
        else
          family_payload = result.success.last
          self.set(cv3_payload: family_payload.to_h.with_indifferent_access)
          p family_payload if Rails.env.test?
        end
      else
        Rails.logger.warn("Publish Family Exception family_id: #{self.id}: #{result.failure}")
        p result.failure
      end
    end
  end
end
