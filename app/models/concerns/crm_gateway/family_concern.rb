# frozen_string_literal: true

module CrmGateway
  # Module for keeping extra family methods related to crm gateway
  module FamilyConcern
    extend ActiveSupport::Concern

    CRITICAL_CRM_ATTRIBUTES = ['first_name', 'last_name', 'dob', 'encrypted_ssn'].freeze

    included do
      before_save :assign_critical_previous_changes
      after_save :trigger_crm_family_update_publish_after_save
      after_create :trigger_crm_family_update_after_create
    end

    def assign_critical_previous_changes
      return unless EnrollRegistry.feature_enabled?(:crm_update_family_save)
      relevant_previous_changes_array = []
      self.family_members.each do |family_member|
        previous_changes_attributes = family_member.person.previous_changes.reject { |key, _value| CRITICAL_CRM_ATTRIBUTES.exclude?(key) }
        relevant_previous_changes_array << previous_changes_attributes.merge!(hbx_id: family_member.person.hbx_id) unless previous_changes_attributes.blank?
      end
      # Record family member count to update on family members
      relevant_previous_changes_array << {family_member_count: self.family_members.count}
      self.relevant_previous_changes = relevant_previous_changes_array
    end

    # After create action, family will trigger to CRM as long as CRM_update_family_save is enabled
    def trigger_crm_family_update_after_create
      return unless EnrollRegistry.feature_enabled?(:crm_update_family_save)
      puts("Triggering CRM family update publish for family with mongo id #{self.id}")
      result = ::Operations::Families::SugarCrm::PublishFamily.new.call(self)
      puts result.inspect
      if result.success?
        p result.value!
      else
        p result.failure
      end
      result
    end

    # Any time after the family is saved, the CRM publish will only trigger if the family's family_member
    # person records have any of the CRITICAL_CRM_ATTRIBUTES listed above changed from their previous values
    def trigger_crm_family_update_publish_after_save
      return unless EnrollRegistry.feature_enabled?(:crm_update_family_save)
      # Only publish on critical changes
      current_previous_changes = self.relevant_previous_changes
      previous_family_member_count = self.relevant_previous_changes.detect { |element| element.key?(:family_member_count) }[:family_member_count]
      new_family_member_count = self.family_members.count
      new_previous_changes = []
      self.family_members.map do |member|
        critical_changes = member.person.previous_changes.reject { |key, _value| CRITICAL_CRM_ATTRIBUTES.exclude?(key) }
        critical_changes.merge!(hbx_id: member.person.hbx_id) if critical_changes.present?
        next unless critical_changes.present?
        member_previous_changes_hash = current_previous_changes.detect { |attributes_hash| attributes_hash['hbx_id'] == member.person.hbx_id }
        new_previous_changes << critical_changes if member_previous_changes_hash != critical_changes
        # Record family member count to update on family members
      end
      # Consider it a change if family member count has changed
      new_previous_changes << new_family_member_count if new_family_member_count != previous_family_member_count
      return nil if new_previous_changes.blank?
      puts("Triggering CRM family update publish for family with mongo id #{self.id}")
      result = ::Operations::Families::SugarCrm::PublishFamily.new.call(self)
      puts result.inspect
      if result.success?
        p result.value!
      else
        p result.failure
      end
      result
    end
  end
end
