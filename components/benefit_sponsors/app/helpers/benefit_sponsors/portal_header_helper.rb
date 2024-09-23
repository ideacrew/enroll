module BenefitSponsors
  module PortalHeaderHelper
    include ::L10nHelper

    # rubocop:disable Layout/SpaceAroundOperators
    def benefit_sponsors_portal_display_name(controller)
      if current_user.nil?
        translated_header_portal_link("welcome.index.byline")
      elsif current_user.try(:has_hbx_staff_role?)
        portal_link_with_image('icons/icon-exchange-admin.png', " &nbsp; I'm an Admin", main_app.exchanges_hbx_profiles_root_path, class: "portal")
      elsif current_user.person.try(:broker_role)
        portal_link_with_image('icons/icon-expert.png', " &nbsp; I'm a Broker", benefit_sponsors.profiles_broker_agencies_broker_agency_profile_path(id: current_user.person.broker_role.benefit_sponsors_broker_agency_profile_id), class: "portal")
      elsif current_user.try(:person).try(:csr_role) || current_user.try(:person).try(:assister_role)
        portal_link_with_image('icons/icon-expert.png', " &nbsp; I'm a Trained Expert", home_exchanges_agents_path, class: "portal")
      elsif current_user.person && current_user.person.active_employee_roles.any?
        portal_link_with_image('icons/icon-individual.png', " &nbsp; I'm an #{controller=='employer_profiles'? 'Employer': 'Employee'}", family_account_path, class: "portal")
      elsif (controller_path.include?("insured") && current_user.try(:has_consumer_role?))
        if current_user.identity_verified_date.present?
          portal_link_with_image('icons/icon-family.png', " &nbsp; Individual and Family", family_account_path, class: "portal")
        else
          portal_link_with_image_and_no_navigation('icons/icon-family.png', " &nbsp; Individual and Family", class: "portal")
        end
      elsif current_user.try(:has_broker_agency_staff_role?)
        portal_link_with_image('icons/icon-expert.png', " &nbsp; I'm a Broker", benefit_sponsors.profiles_broker_agencies_broker_agency_profile_path(id: current_user.person.broker_role.benefit_sponsors_broker_agency_profile_id), class: "portal")
      elsif current_user.try(:has_employer_staff_role?)
        portal_link_with_image(
          'icons/icon-business-owner.png',
          " &nbsp; I'm an Employer",
          profiles_employers_employer_profile_path(current_user.person.active_employer_staff_roles.first.benefit_sponsor_employer_profile_id, tab: 'home'),
          class: "portal"
        )
      elsif current_user.has_general_agency_staff_role?
        portal_link_with_image('icons/icon-expert.png', " &nbsp; I'm a General Agency", general_agencies_root_path, class: "portal")
      else
        translated_header_portal_link("welcome.index.byline")
      end
    end
    # rubocop:enable Layout/SpaceAroundOperators

    def translated_header_portal_link(*args)
      content_tag("a", class: "portal") do
        l10n(*args).html_safe
      end
    end

    def portal_link_with_image(image_path, link_text, *args)
      link_to(*args) do
        concat image_tag(image_path)
        concat sanitize(link_text)
      end
    end

    def portal_link_with_image_and_no_navigation(image_path, link_text, *args)
      content_tag("a", *args) do
        concat image_tag(image_path)
        concat sanitize(link_text)
      end
    end
  end
end
