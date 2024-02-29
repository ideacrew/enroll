module Notifier
  module ApplicationHelper
    # rubocop:disable Layout/SpaceAroundOperators
    def portal_display_name(controller)
      if current_user.nil?
        setting_portal_link(EnrollRegistry[:enroll_app].setting(:header_message).item)
      elsif current_user.try(:has_hbx_staff_role?)
        portal_link_with_image('icons/icon-exchange-admin.png', " &nbsp; I'm an Admin", main_app.exchanges_hbx_profiles_root_path, class: "portal")
      elsif current_user.person.try(:broker_role)
        portal_link_with_image('icons/icon-expert.png', " &nbsp; I'm a Broker", broker_agencies_profile_path(id: current_user.person.broker_role.broker_agency_profile_id), class: "portal")
      elsif current_user.try(:person).try(:csr_role) || current_user.try(:person).try(:assister_role)
        portal_link_with_image('icons/icon-expert.png', " &nbsp; I'm a Trained Expert", home_exchanges_agents_path, class: "portal")
      elsif current_user.person && current_user.person.active_employee_roles.any?
        portal_link_with_image('icons/icon-individual.png', " &nbsp; I'm an #{controller=='employer_profiles'? 'Employer': 'Employee'}", family_account_path, class: "portal")
      elsif (controller_path.include?("insured") && current_user.try(:has_consumer_role?))
        if current_user.identity_verified_date.present?
          portal_link_with_image('icons/icon-family.png', " &nbsp; Individual and Family", family_account_path, class: "portal")
        else
          portal_link_with_image_and_no_navigation('icons/icon-family.png', " &nbsp; Individual and Family", class: portal)
        end
      elsif current_user.try(:has_broker_agency_staff_role?)
        portal_link_with_image('icons/icon-expert.png', " &nbsp; I'm a Broker", broker_agencies_profile_path(id: current_user.person.broker_role.broker_agency_profile_id), class: "portal")
      elsif current_user.try(:has_employer_staff_role?)
        portal_link_with_image('icons/icon-business-owner.png', " &nbsp; I'm an Employer", employers_employer_profile_path(id: current_user.person.active_employer_staff_roles.first.employer_profile_id), class: "portal")
      elsif current_user.has_general_agency_staff_role?
        portal_link_with_image('icons/icon-expert.png', " &nbsp; I'm a General Agency", general_agencies_root_path, class: "portal")
      else
        setting_portal_link(EnrollRegistry[:enroll_app].setting(:header_message).item)
      end
    end
    # rubocop:enable Layout/SpaceAroundOperators

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

    def setting_portal_link(setting)
      content_tag("a", class: "portal") do
        setting.html_safe
      end
    end

    def get_header_text(controller_name)
      portal_display_name(controller_name)
    end

    def site_main_web_address_business
      EnrollRegistry[:enroll_app].setting(:main_web_address).item_business
    end

    def site_faqs_url
      Settings.site.faqs_url
    end

    def dc_exchange?
      Settings.aca.state_abbreviation.upcase == 'DC'
    end

    def site_short_name
      EnrollRegistry[:enroll_app].setting(:short_name).item
    end

    #TODO: Add a similar notice attachment setting for DC
    def shop_non_discrimination_attachment
      Settings.notices.shop.attachments.non_discrimination_attachment
    end

    #TODO: Add a similar notice attachment setting for DC
    def shop_envelope_without_address
      Settings.notices.shop.attachments.envelope_without_address
    end

    def ivl_non_discrimination_attachment
      Settings.notices.individual.attachments.non_discrimination_attachment
    end

    def ivl_envelope_without_address
      Settings.notices.individual.attachments.envelope_without_address
    end

    def ivl_blank_page_attachment
      Settings.notices.individual.attachments.blank_page_attachment
    end

    def ivl_voter_application
      Settings.notices.individual.attachments.voter_application
    end

    def calculate_age_by_dob(dob)
      now = TimeKeeper.date_of_record
      now.year - dob.year - (now.month > dob.month || (now.month == dob.month && now.day >= dob.day) ? 0 : 1)
    end
  end
end
