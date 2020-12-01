# frozen_string_literal: true

class HomePage

  def self.employee_portal_btn
    '//a[contains(text(), "Employee Portal")]'
  end

  def self.consumer_family_portal_btn
    '(//a[contains(text(), "Consumer/Family Portal")])[1]'
  end

  def self.assisted_consumer_family_portal_btn
    '(//a[contains(text(), "Assisted Consumer/Family Portal")])[1]'
  end

  def self.returning_user_btn
    '//a[contains(text(), "Returning User")]'
  end

  def self.employer_portal_btn
    '//a[contains(text(), "Employer Portal")]'
  end

  def self.broker_agency_portal_btn
    '//a[contains(text(), "Broker Agency Portal")]'
  end

  def self.general_agency_portal_btn
    '//a[contains(text(), "General Agency Portal")]'
  end

  def self.hbx_portal_btn
    '.hbx-portal'
  end

  def self.broker_registration_btn
    '.broker-registration'
  end

  def self.general_agency_registration_btn
    '//a[contains(text(), "General Agency Registration")]'
  end
end