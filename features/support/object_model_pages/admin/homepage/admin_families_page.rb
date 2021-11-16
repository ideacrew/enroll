# frozen_string_literal: true

class AdminFamiliesPage
  
  def self.all_tab
    'div[id="Tab:all"]'
  end

  def self.individual_enrolled_tab
    'div[id="Tab:by_enrollment_individual_market"]'
  end

  def self.employer_sponsered_coverage_enrolled_tab
    'div[id="Tab:by_enrollment_shop_market"]'
  end

  def self.non_enrolled_tab
    'div[id="Tab:non_enrolled"]'
  end

  def self.csv_tab_text
    'CSV'
  end

  def self.excel_tab_text
    'Excel'
  end

  def self.actions_drop_down_toggle
    '.dropdown-toggle'
  end

  def self.actions_drop_down_text
    'Actions'
  end

  def self.add_sep_text
    'Add SEP'
  end

  def self.create_eligibility_text
    'Create Eligibility'
  end

  def self.cancel_enrollment_text
    'Cancel Enrollment'
  end

  def self.terminate_enrollment_text
    'Terminate Enrollment'
  end

  def self.change_enrollment_end_date_text
    'Change Enrollment End Date'
  end

  def self.reinstate_text
    'Reinstate'
  end

  def self.edit_dob_ssn_text
    'Edit DOB / SSN'
  end

  def self.view_username_email_text
    'View Username and Email'
  end
  
  def self.collapse_form_text
    'Collapse Form'
  end

  def self.paper_text
    'Paper'
  end

  def self.phone_text
    'Phone'
  end

  def self.transition_family_members_text
    'Transition Family Members'
  end

  def self.new_ssn
    'person[ssn]'
  end

  def self.new_dob
    'jq_datepicker_ignore_person[dob]'
  end
end    