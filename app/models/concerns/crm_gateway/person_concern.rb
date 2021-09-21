# frozen_string_literal: true

module CrmGateway
  # Methods related to publishing data to CRM gateway
  module PersonConcern
    extend ActiveSupport::Concern

    included do
      after_save :trigger_primary_subscriber_publish
    end

    def determine_last_ea_action
      family_id = primary_family.id.to_s
      financial_assistance_applications = FinancialAssistance::Application.where(family_id: family_id)
      # Returns nil if neither of those are present
      return "determined" if financial_assistance_applications&.last&.aasm_state == "determined"
      return "draft" if financial_assistance_applications&.last&.aasm_state == "draft"
      consumer_role&.identity_verified? ? "fully_verified" : "unverified"
    end

    def trigger_primary_subscriber_publish
      return unless EnrollRegistry.feature_enabled?(:crm_publish_primary_subscriber)
      return unless has_active_consumer_role?
      return unless primary_family.present? && self == primary_family.primary_person
      puts("Triggering CRM primary subscriber update publish for person with mongo id #{self.id}")
      ::Operations::People::SugarCrm::PublishPrimarySubscriber.new.call(
        self,
        last_ea_action: determine_last_ea_action
      )
    end
  end
end
