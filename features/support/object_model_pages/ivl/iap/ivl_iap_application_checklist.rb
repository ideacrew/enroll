# frozen_string_literal: true

#application_checklist
class IvlIapApplicationChecklist

  def self.application_checklist_text
    'div.col-lg-9 .darkblue'
  end

  def self.view_complete_application_checklist
    'a.interaction-click-control-view-the-complete-application-checklist'
  end

  def self.continue_btn
    if EnrollRegistry[:bs4_consumer_flow].enabled?
     '.interaction-click-control-continue-to-next-step'
    else 
    '#btn-continue'
    end
  end

  def self.previous_link
    '.interaction-click-control-previous'
  end

  def self.save_and_exit_link
    '.interaction-click-control-save---exit'
  end

  def self.help_me_sign_up_btn
    'div[class="btn btn-default btn-block help-me-sign-up"]'
  end

  def self.log_out_btn
    'a[class="header-text interaction-click-control-logout"]'
  end

  def self.begin_application_btn
    '.interaction-click-control-begin-application'
  end
end