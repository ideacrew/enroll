# frozen_string_literal: true

module CrmGateway
  # Methods related to publishing data to CRM gateway
  module PersonConcern
    extend ActiveSupport::Concern

    def trigger_primary_subscriber_publish
      return unless EnrollRegistry.feature_enabled?(:crm_publish_primary_subscriber)
      return unless has_active_consumer_role?
      return unless primary_family.present? && self == primary_family.primary_person
      puts("Triggering CRM primary subscriber update publish for person with mongo id #{self.id}")
      ::Operations::People::SugarCrm::PublishPrimarySubscriber.new.call(self)
    end
  end
end
