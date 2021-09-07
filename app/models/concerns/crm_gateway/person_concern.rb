# frozen_string_literal: true

module CrmGateway
  # Methods related to publishing data to CRM gateway
  module PersonConcern
    extend ActiveSupport::Concern

    included do
      after_save :trigger_primary_subscriber_publish
    end

    def trigger_primary_subscriber_publish
      return unless EnrollRegistry.feature_enabled?(:crm_publish_primary_subscriber)
      return if Rails.env.test?
      return unless has_active_consumer_role?
      return unless self == self&.primary_family&.primary_person
      ::Operations::People::CrmGateway::PublishPrimarySubscriber.new.call(self.attributes)
    end
  end
end
