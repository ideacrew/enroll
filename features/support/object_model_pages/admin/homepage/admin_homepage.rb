# frozen_string_literal: true

#exchanges/hbx_profiles
class AdminHomepage

  def self.home_icon
    'i[class="fas fa-home fa-lg"]'
  end

  def self.families_dropown
    '#families_dropdown'
  end

  def self.families_btn
    'a[class="interaction-click-control-families"]'
  end

  def self.outstanding_ver_btn
    '.interaction-click-control-outstanding-verifications'
  end

  def self.new_consumer_app_btn
    '.interaction-click-control-new-consumer-application'
  end

  def self.identity_ver_btn
    '.interaction-click-control-identity-verification'
  end

  def self.dc_resident_app_btn
    '.interaction-click-control-dc-resident-application'
  end

  def self.employers_btn
    '.interaction-click-control-employers'
  end

  def self.user_accounts_btn
    '.interaction-click-control-user-accounts'
  end

  def self.issuers_btn
    '.interaction-click-control-issuers'
  end

  def self.brokers_dropdown
    '.interaction-click-control-brokers'
  end

  def self.broker_app_btn
    '.interaction-click-control-broker-applications'
  end

  def self.broker_agencies_btn
    '.interaction-click-control-broker-agencies'
  end

  def self.general_agencies_btn
    '.interaction-click-control-general-agencies'
  end

  def self.agency_staff_btn
    '.interaction-click-control-agency-staff'
  end

  def self.admin_dropdown
    '.interaction-click-control-admin'
  end

  def self.calendar_btn
    '.interaction-click-control-calendar'
  end

  def self.config_btn
    '.interaction-click-control-config'
  end

  def self.staff_btn
    '.interaction-click-control-staff'
  end

  def self.orphan_accounts_btn
    '.interaction-click-control-orphan-accounts'
  end

  def self.bulk_notices_btn
    '.interaction-click-control-bulk-notices'
  end

  def self.manage_seps_btn
    '.interaction-click-control-manage-seps'
  end

  def self.inbox_btn
    'a[class^="visible interaction-click-control-inbox"]'
  end

  def self.notices_btn
    '.interaction-click-control-notices'
  end

  def self.help_link
    '.interaction-click-control-help'
  end

  def self.log_out_link
    '.interaction-click-control-logout'
  end

  def self.medicaid_banner_text
    '[data-cuke="medicaid-banner-text"]'
  end

  def self.chat_button
    '[data-cuke="chat-button"]'
  end

  def self.bot_button
    '[data-cuke="bot-button"]'
  end

  def self.chat_widget_title
    ".cx-title"
  end

  def self.failed_validation_text
    "eligibility failed"
  end

  def self.remove_mailing_address
    '[data-cuke="remove_mailing_address"]'
  end

  # any non-dc state
  def self.non_dc_state
    '.interaction-choice-control-inputstate-1'
  end

  def self.shop_for_employer
    '[data-cuke="shop_for_employer"]'
  end
end