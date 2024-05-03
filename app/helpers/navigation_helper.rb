# frozen_string_literal: true

module NavigationHelper
  def tell_us_about_yourself_active? # rubocop:disable Metrics/CyclomaticComplexity TODO: Remove this
    return true if controller_name == "consumer_roles" && ['edit', 'ridp_agreement'].include?(action_name)
    return true if controller_name == "interactive_identity_verifications"
    return true if ["help_paying_coverage", "application_checklist", "application_year_selection"].include?(action_name)
    return true if controller_name == "family_members" && action_name == "index"
    return true if controller_name == "family_relationships" && action_name == "index"
  end

  def account_registration_active?
    ["search", "match"].include?(action_name)
  end

  def tell_us_about_yourself_current_step?
    return true if controller_name == "consumer_roles" && ['edit', 'ridp_agreement'].include?(action_name)
    return true if controller_name == "interactive_identity_verifications"
    return true if ["help_paying_coverage", "application_checklist", "application_year_selection"].include?(action_name)
  end

  def family_members_index_active?
    return true if controller_name == "family_members" && action_name == "index"
    return true if controller_name == "family_relationships" && action_name == "index"
  end

  def family_members_index_current_step?
    return true if controller_name == "family_relationships" && action_name == "index"
    return true if controller_name == "family_members" && action_name == "index"
  end

  def sign_up_nav_options
    [
      {step: 1, label: l10n('personal_information')},
      {step: 2, label: l10n('tell_us_about_yourself')},
      {step: 3, label: l10n('family_info')}
    ]
  end
end
