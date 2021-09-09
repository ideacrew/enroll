# frozen_string_literal: true

module FinancialAssistance
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

    def application_checklist_previous_url(application)
      return financial_assistance.application_year_selection_application_path(application) if FinancialAssistanceRegistry.feature_enabled?(:iap_year_selection)
      main_app.help_paying_coverage_insured_consumer_role_index_path
    end
  end
end
