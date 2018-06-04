module BenefitSponsors
  module ApplicationHelper

    def bootstrap_class_for flash_type
      case flash_type
        when "notice"
          "alert-info"
        when "success"
          "alert-success"
        when "error"
          "alert-danger"
        when "alert"
          "alert-warning"
      end
    end

    def flash_messages(opts = {})
      flash.each do |msg_type, message|
        concat(content_tag(:div, message, class: "alert #{bootstrap_class_for(msg_type)} alert-dismissible fade show") do
          concat content_tag(:button, 'x', class: "close", data: { dismiss: 'alert' })
          concat message
        end)
      end
      nil
    end

    def format_date(date_value)
      date_value.strftime("%m/%d/%Y") if date_value.respond_to?(:strftime)
    end

    def menu_tab_class(a_tab, current_tab)
      (a_tab == current_tab) ? raw(" class=\"active\"") : ""
    end

    def get_benefit_sponsors_header_text(controller_name)
      benefit_sponsors_portal_display_name(controller_name)
    end

    def user_first_name_last_name_and_suffix
      if signed_in?
        current_user.person.try(:first_name_last_name_and_suffix) ? current_user.person.first_name_last_name_and_suffix : (current_user.oim_id).downcase
      end
    end

    def copyright_notice
      raw("<span class='copyright'><i class='fa fa-copyright fa-lg' aria-hidden='true'></i> #{Settings.site.copyright_period_start}-#{TimeKeeper.date_of_record.year} #{Settings.site.short_name}. All Rights Reserved.</span>")
    end

    def render_flash
      rendered = []
      flash.each do |type, messages|
        if messages.respond_to?(:each)
          messages.each do |m|
            rendered << render(:partial => 'layouts/flash', :locals => {:type => type, :message => m}) unless m.blank?
          end
        else
          rendered << render(:partial => 'layouts/flash', :locals => {:type => type, :message => messages}) unless messages.blank?
        end
      end
      rendered.join('').html_safe
    end

    def retrieve_show(provider, message)
      inboxes_message_path(provider, message_id: message.id)
    end

    def find_and_sort_inbox_messages(provider, folder)
      provider.inbox.messages.select {|m| folder == (m.folder.try(:capitalize) || 'Inbox')}.sort_by(&:created_at).reverse
    end

    def retrieve_inbox(provider, folder: 'inbox')
      broker_agency_mailbox = inbox_profiles_broker_agencies_broker_agency_profile_path(id: provider.id.to_s, folder: folder)
      return broker_agency_mailbox if provider.try(:broker_role)
      case (provider.model_name.name.split('::').last)
        when "AcaShopDcEmployerProfile"
          inbox_profiles_employers_employer_profile_path(id: provider.id.to_s, folder: folder)
        when "HbxProfile"
          #TODO fix it for HBX profile
        when "BrokerAgencyProfile"
          inbox_profiles_broker_agencies_broker_agency_profile_path(id: provider.id.to_s, folder: folder)
        when "GeneralAgencyProfile"
          #TODO FIX IT for GA
      end
    end

    def benefit_sponsor_display_families_tab(user,profile_id)
      if user.present?
        user.has_broker_agency_staff_role? || user.has_general_agency_staff_role? || user.is_benefit_sponsor_active_broker?(profile_id)
      end
    end

    def format_name(first_name: nil, last_name: nil, middle_name: nil, name_sfx: nil)
      given_name = [first_name, middle_name].reject(&:nil? || empty?).join(' ')
      sir_name  = content_tag(:strong, mixed_case(last_name))
      raw([mixed_case(given_name), sir_name, name_sfx].reject(&:nil? || empty?).join(' '))
    end
  end
end
