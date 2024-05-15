# frozen_string_literal: true

# Here is a comment
module Bs4
  # this is used with the new bs4 header
  module Bs4HeaderHelper
    include L10nHelper
    include ApplicationHelper

    def bs4_portal_type(controller) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      if current_user.nil?
        nil
      elsif current_user.try(:has_hbx_staff_role?)
        link_to(l10n("layout.header.role.admin"), main_app.exchanges_hbx_profiles_root_path)
      elsif display_i_am_broker_for_consumer?(current_user.person) && controller_path.exclude?('general_agencies')
        link_to(l10n("layout.header.role.broker"), get_broker_profile_path)
      elsif current_user.try(:person).try(:csr_role) || current_user.try(:person).try(:assister_role)
        link_to(l10n("layout.header.role.trained_expert"), main_app.home_exchanges_agents_path)
      elsif current_user.person&.active_employee_roles&.any?
        if controller_path.include?('broker_agencies')
          link_to(l10n("layout.header.role.broker"), get_broker_profile_path)
        elsif controller_path.include?('general_agencies')
          link_to(l10n("layout.header.role.general_agency"), benefit_sponsors.profiles_general_agencies_general_agency_profile_path(id: current_user.person.general_agency_staff_roles.first.benefit_sponsors_general_agency_profile_id))
        elsif controller == 'employer_profiles' || controller_path.include?('employers')
          #current user has both broker_agency staff role and employee role but not employer_staff_roles
          if current_user.person.active_employer_staff_roles.present?
            employer_profile_path = benefit_sponsors.profiles_employers_employer_profile_path(id: current_user.person.active_employer_staff_roles.first.benefit_sponsor_employer_profile_id, :tab => 'home')
            link_to(l10n("layout.header.role.employer"), employer_profile_path)
          elsif current_user.try(:has_broker_agency_staff_role?)
            link_to(l10n("layout.header.role.broker"), get_broker_profile_path)
          end
        else
          link_to(l10n("layout.header.role.employee"), main_app.family_account_path)
        end
      elsif (controller_path.include?("insured") && current_user.try(:has_consumer_role?)) ||
            (EnrollRegistry.feature_enabled?(:financial_assistance) && controller_path.include?("financial_assistance") && current_user.try(:has_consumer_role?))
        if current_user.identity_verified_date.present?
          link_to(l10n("layout.header.role.individual_and_family"), main_app.family_account_path)
        else
          link_to(l10n("layout.header.role.individual_and_family"), 'javascript:;')
        end
      # rubocop:disable Lint/DuplicateBranch
      elsif current_user.try(:has_broker_agency_staff_role?) && controller_path.exclude?('general_agencies') && controller_path.exclude?('employers')
        link_to(l10n("layout.header.role.broker"), get_broker_profile_path)
      # rubocop:enable Lint/DuplicateBranch
      elsif current_user.try(:has_general_agency_staff_role?)
        if current_user.try(:has_employer_staff_role?) && controller_path.include?('employers')
          link_to(l10n("layout.header.role.employer"), benefit_sponsors.profiles_employers_employer_profile_path(id: current_user.person.active_employer_staff_roles.first.benefit_sponsor_employer_profile_id, :tab => 'home'))
        else
          link_to(l10n("layout.header.role.general_agency"), benefit_sponsors.profiles_general_agencies_general_agency_profile_path(id: current_user.person.active_general_agency_staff_roles.first.benefit_sponsors_general_agency_profile_id))
        end
      elsif current_user.try(:has_employer_staff_role?)
        link_to(l10n("layout.header.role.employer"), benefit_sponsors.profiles_employers_employer_profile_path(id: current_user.person.active_employer_staff_roles.first.benefit_sponsor_employer_profile_id, :tab => 'home'))
      end
    end

    def get_broker_profile_path # rubocop:disable Naming/AccessorMethodName
      @broker_role ||= current_user.person.broker_role
      broker_agency_profile = @broker_role&.broker_agency_profile
      benefit_sponsors.profiles_broker_agencies_broker_agency_profile_path(id: @broker_role.benefit_sponsors_broker_agency_profile_id) if broker_agency_profile.is_a?(BenefitSponsors::Organizations::BrokerAgencyProfile)
    end

    def display_i_am_broker_for_consumer?(person)
      return if person.blank?
      if EnrollRegistry.feature_enabled?(:broker_role_consumer_enhancement) && person.has_active_consumer_role?
        broker_role = person.broker_role
        matching_basr = person.broker_agency_staff_roles.where(
          benefit_sponsors_broker_agency_profile_id: broker_role&.benefit_sponsors_broker_agency_profile_id
        ).first
        broker_role.present? && broker_role.active? && matching_basr.present? && matching_basr.active?
      else
        person.broker_role.present?
      end
    end
  end
end
