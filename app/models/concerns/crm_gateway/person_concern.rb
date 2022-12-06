# frozen_string_literal: true

module CrmGateway
  # Methods related to publishing data to CRM gateway
  module PersonConcern
    extend ActiveSupport::Concern
    included do
      after_save :trigger_async_publish
    end

    def trigger_async_publish
      return unless EnrollRegistry.feature_enabled?(:crm_publish_primary_subscriber)
      return unless has_active_consumer_role?
      return unless primary_family.present? && self == primary_family.primary_person
      CrmWorker.perform_async(self.id.to_s, self.class.to_s, :trigger_primary_subscriber_publish)
    end

    def trigger_primary_subscriber_publish
      puts("Triggering CRM primary subscriber update publish for person with mongo id #{self.id}")
      result = ::Operations::People::SugarCrm::PublishPrimarySubscriber.new.call(self)
      # Update column directly without callbacks
      if result.success?
        person_payload = result.success.last
        self.set(cv3_payload: person_payload.to_h.with_indifferent_access)
        p person_payload if Rails.env.test?
      else
        Rails.logger.warn("Publish Primary Subscriber Exception person_hbx_id: #{self.hbx_id}: #{result.failure}")
        p result.failure
      end
    end
  end
end
