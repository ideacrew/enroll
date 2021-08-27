# frozen_string_literal: true

module CrmGateway
  # Family concern to handle post save sugar CRM publish events
  # included if EnrollRegistry.feature_enabled?(:crm_update_family_save)
  module FamilyConcern
    extend ActiveSupport::Concern

    included do
      after_save :trigger_crm_family_update_publish
    end

    def trigger_crm_family_update_publish
      params = self.attributes
      ::Operations::Families::CrmGateway::UpdateFamily.new.call(params) unless Rails.env.test?
    end
  end
end
