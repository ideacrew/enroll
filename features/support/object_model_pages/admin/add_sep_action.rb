# frozen_string_literal: true

#admin/families tab/ add sep action
class AddSepAction

  def self.actions_drop_down_toggle
    '.dropdown-toggle'
  end

  def self.actions_drop_down_text
    'Actions'
  end

  def self.admin_comment
    '#admin_comment'
  end

  def self.add_sep_text
    'Add SEP'
  end

  def self.sep_event_date
    'event_date'
  end

  def self.sep_title
    '.title'
  end

  def self.select_sep_reason_dropdown
    '.admin_selected_sep_reason .selectric span.label'
  end

  def self.select_sep_reason
    '.admin_selected_sep_reason .selectric-items .selectric-scroll li'
  end

  def self.select_sep_options_dropdown
    '.admin_effective_on_kind_options .selectric span.label'
  end

  def self.select_sep_option_kind
    '.admin_effective_on_kind_options .selectric-items .selectric-scroll li'
  end

  def self.sep_end_on
    'end_on'
  end

  def self.coverage_renewal_flag
    'coverage_renewal_flag'
  end

  def self.sep_reason_text
    'A medical emergency prevented enrollment'
  end

  def self.sep_option_kind_text
    '15th of month'
  end

  def self.submit_button
    'Submit'
  end

  def self.confirmation_text
    'Are you sure you want to add SEP to prior plan year?'
  end

  def self.popup_confirmation
    '.btn-confirmation'
  end
end
