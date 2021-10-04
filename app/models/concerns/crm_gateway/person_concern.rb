# frozen_string_literal: true

module CrmGateway
  # Methods related to publishing data to CRM gateway
  module PersonConcern
    extend ActiveSupport::Concern

    included do
      after_save :trigger_primary_subscriber_publish
    end

    # CRM Primary Subscriber Publish will trigger if:
    # 1) Person has consumer role, primary family, and is the primary person of that family
    # 2) Person has broker role
    def trigger_primary_subscriber_publish
      return unless EnrollRegistry.feature_enabled?(:crm_publish_primary_subscriber)
      return unless (has_active_consumer_role? && primary_family.present? &&
        self == primary_family.primary_person) || has_broker_role?
      puts("Triggering CRM primary subscriber update publish for person with mongo id #{self.id}")
      ::Operations::People::SugarCrm::PublishPrimarySubscriber.new.call(self)
    end
  end
end
