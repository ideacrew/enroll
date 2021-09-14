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
      puts("Triggering CRM family update publish for family with mongo id #{self.id.to_s}")
      ::Operations::Families::CrmGateway::UpdateFamily.new.call(self) unless Rails.env.test?
    end
  end
end
