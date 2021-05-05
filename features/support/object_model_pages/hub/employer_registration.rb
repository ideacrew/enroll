# frozen_string_literal: true

#Has fields related to employer registration portal page under my hub account
#benefit_sponsors/profiles/employers/employer_profiles/new_employer_profile?person_id=605c8c7a7d267570738288a8&profile_type=benefit_sponsor
class EmployerRegistration

  def self.employer_registration_tab
    '#ui-id-1'
  end

  def self.employer_staff_tab
    '#ui-id-2'
  end

  def self.first_name
    'agency[staff_roles_attributes][0][first_name]'
  end

  def self.last_name
    'agency[staff_roles_attributes][0][last_name]'
  end

  def self.dob
    'agency[staff_roles_attributes][0][dob]'
  end

  def self.email
    'agency[staff_roles_attributes][0][email]'
  end

  def self.area_code
    'agency[staff_roles_attributes][0][area_code]'
  end

  def self.number
    'agency[staff_roles_attributes][0][number]'
  end

  def self.is_applying_coverage
    'agency[staff_roles_attributes][0][coverage_record][is_applying_coverage]'
  end

  def self.ssn
    'agency[staff_roles_attributes][0][coverage_record][ssn]'
  end

  def self.gender
    'agency[staff_roles_attributes][0][coverage_record][gender]'
  end

  def self.hired_on
    'agency[staff_roles_attributes][0][coverage_record][hired_on]'
  end

  def self.address_1
    'agency[staff_roles_attributes][0][coverage_record][address][address_1]'
  end

  def self.address_2
    'agency[staff_roles_attributes][0][coverage_record][address][address_2]'
  end

  def self.city
    'agency[staff_roles_attributes][0][coverage_record][address][city]'
  end

  def self.state
    'agency[staff_roles_attributes][0][coverage_record][address][state]'
  end

  def self.zip
    'agency[staff_roles_attributes][0][coverage_record][address][zip]'
  end

  def self.coverage_record_email_kind
    'agency[staff_roles_attributes][0][coverage_record][email][kind]'
  end

  def self.coverage_record_email_address
    'agency[staff_roles_attributes][0][coverage_record][email][address]'
  end

  def self.legal_name
    'agency[organization][legal_name]'
  end

  def self.dba
    'agency[organization][dba]'
  end

  def self.fein
    'agency[organization][dba]'
  end

  def self.entity_kind
    'agency[organization][entity_kind]'
  end

  def self.org_address
    'agency[organization][profile][office_locations_attributes][0][address][address_1]'
  end

  def self.address_kind
    'agency[organization][profile][office_locations_attributes][0][address][kind]'
  end

  def self.org_address_2
    'agency[organization][profile][office_locations_attributes][0][address][address_2]'
  end

  def self.org_city
    'agency[organization][profile][office_locations_attributes][0][address][city]'
  end

  def self.org_state
    'agency[organization][profile][office_locations_attributes][0][address][state]'
  end

  def self.org_zip
    'agency[organization][profile][office_locations_attributes][0][address][zip]'
  end

  def self.org_area_code
    'agency[organization][profile][office_locations_attributes][0][phone][area_code]'
  end

  def self.org_number
    'agency[organization][profile][office_locations_attributes][0][phone][number]'
  end

  def self.add_office_location_btn
    'a[id="addOfficeLocation"]'
  end

  def self.contact_method
    'agency[organization][profile][contact_method]'
  end

  def self.add_portal_btn
    'input[class="btn btn-primary pull-right mt-2"]'
  end
end