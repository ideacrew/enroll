# frozen_string_literal: true

module Verifications
  # this helper is only used to determine if a user can view/modify a consumer's Alive Status verification
  module AliveStatusHelper
    # method added specifically to handle the displaying of 'Alive Status'
    # this verification type should always be visible to admin
    # but should only display for consumers/brokers/broker agency staff if the validation_status is 'outstanding'
    def can_display_or_modify_type?(verif_type)
      return true unless verif_type&.type_name == 'Alive Status'
      return false unless EnrollRegistry.feature_enabled?(:alive_status)
      return true if current_user.has_hbx_staff_role?

      previous_states = verif_type&.type_history_elements&.pluck(:from_validation_status)&.compact
      return true if previous_states&.include?('outstanding')
      return true if verif_type&.validation_status == 'outstanding'

      false
    end
  end
end