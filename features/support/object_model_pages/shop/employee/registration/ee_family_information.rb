# frozen_string_literal: true

#insured/family_members?employee_role_id
class EmployeeFamilyInformation

  def self.edit_btn
    '.fa-pencil-alt'
  end

  def self.first_name
    'person[first_name]'
  end

  def self.middle_name
    'person[middle_name]'
  end

  def self.last_name
    'person[last_name]'
  end

  def self.suffix_dropdown
    'div[id="personal_info"] span[class="label"]'
  end

  def self.male_radiobtn
    'label[for="radio_male"] span'
  end

  def self.female_radiobtn
    'label[for="radio_female"] span'
  end

  def self.continue_btn
    '#btn-continue'
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

  def self.save_btn
    'span[class="btn btn-lg btn-primary btn-br"]'
  end

  def self.add_new_person
    'span[class="fa-icon fa-stack plus-mr"]'
  end

  def self.dependent_first_name
    'dependent[first_name]'
  end

  def self.dependent_middle_name
    'dependent[middle_name]'
  end

  def self.dependent_last_name
    'dependent[last_name]'
  end

  def self.dependent_dob
    'jq_datepicker_ignore_dependent[dob]'
  end

  def self.dependent_ssn
    'dependent[ssn]'
  end

  def self.dependent_no_ssn_checkbox
    '#dependent_no_ssn'
  end

  def self.dependent_male_radiobtn
    'label[for="radio_male"] span'
  end

  def self.dependent_female_radiobtn
    'label[for="radio_female"] span'
  end

  def self.dependent_relationship_dropdown
    '.label'
  end

  def self.spouse
    'div.select-relation li[data-index="1"]'
  end

  def self.child
    'div.select-relation li[data-index="3"]'
  end

  def self.dependent_address_line_one
    'dependent[addresses][0][address_1]'
  end

  def self.dependent_address_line_two
    'dependent[addresses][0][address_2]'
  end

  def self.dependent_city
    'dependent[addresses][0][city]'
  end

  def self.dependent_select_state_dropdown
    'div.home-div span.label'
  end

  def self.dependent_select_dc_state
    'div.selectric-open li[data-index="10"]'
  end

  def self.dependent_select_ma_state
    'div.selectric-open li[data-index="24"]'
  end

  def self.dependent_zip
    'dependent[addresses][0][zip]'
  end

  def self.dependent_add_mailing_address_btn
    'span[class="form-action btn btn-default"]'
  end

  def self.confirm_member_btn
    'span[class="btn btn-primary btn-br pull-right mz"]'
  end

  def self.lives_with_primary
    'input[id="dependent_same_with_primary'
  end
end