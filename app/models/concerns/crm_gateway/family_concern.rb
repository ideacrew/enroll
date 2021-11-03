# frozen_string_literal: true

module CrmGateway
  # Module for keeping extra family methods related to crm gateway
  module FamilyConcern
    extend ActiveSupport::Concern
    included do
      after_save :trigger_crm_family_update_publish
    end

    def trigger_crm_family_update_publish
      return unless EnrollRegistry.feature_enabled?(:crm_update_family_save)
      puts("Triggering CRM family update publish for family with mongo id #{self.id}")
      result = ::Operations::Families::SugarCrm::PublishFamily.new.call(self)
      # Update column directly without callbacks
      puts result[0].inspect
      if result.is_a?(Array) && result[0].success?
        family_payload = result[1]
        self.set(cv3_payload: family_payload.to_h.with_indifferent_access)
        p family_payload if Rails.env.test?
      else
        p result.failure
      end
    end
  end
end
