# frozen_string_literal: true

#insured/employee/6047a0d815484347375e41de/edit
class EmployeeContactInformation

  def self.new_address
    '.interaction-click-control-new-address'
  end
  
  def self.address_line1
    'person[addresses_attributes][0][address_1]'
  end
  
  def self.address2_line2
    'person[addresses_attributes][0][address_2]'
  end
  
  def self.city
    'person[addresses_attributes][0][city]'
  end
  
  def self.state
    'person[addresses_attributes][0][state]'
  end
  
  def self.zip
    'person[addresses_attributes][0][zip]'
  end
  
  def self.home_phone
    'person[phones_attributes][0][full_phone_number]'
  end
  
  def self.mobile_phone
    'person[phones_attributes][1][full_phone_number]'
  end
  
  def self.work_phone
    'person[phones_attributes][2][full_phone_number]'
  end
  
  def self.fax_phone
    'person[phones_attributes][3][full_phone_number]'
  end
  
  def self.personal_email_address
    'person[emails_attributes][0][address]'
  end
  
  def self.work_email_address
    'person[emails_attributes][1][address]'
  end
  
  def self.contact_method
    'person[employee_roles_attributes][0][contact_method]'
  end
  
  def self.language_preference
    'person[employee_roles_attributes][0][language_preference]'
  end
  
  def self.continue_button
    '.interaction-click-control-continue'
  end
end  