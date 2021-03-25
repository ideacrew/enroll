# frozen_string_literal: true

#Has fields related to broker registration portal page under my hub account
#benefit_sponsors/profiles/broker_agencies/broker_agency_profiles/new_broker_profile?person_id=605c8c7a7d267570738288a8&profile_type=broker_agency
class BrokerRegistration

  def self.broker_tab
    '#ui-id-1'
  end

  def self.broker_agency_staff_tab
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

  def self.npn
    'agency[staff_roles_attributes][0][npn]'
  end

  def self.legal_name
    'agency[organization][legal_name]'
  end

  def self.dba
    'agency[organization][dba]'
  end

  def self.practice_area_dropdown
    'agency[organization][profile][market_kind]'
  end

  def self.select_languages
    'broker_agency_language_select'
  end

  def self.evening_hours_checkbox
    'agency[organization][profile][working_hours]'
  end

  def self.accept_new_client_checkbox
    'agency[organization][profile][accept_new_clients]'
  end

  def self.address
    'agency[organization][profile][office_locations_attributes][0][address][address_1]'
  end

  def self.kind_dropdown
    'agency[organization][profile][office_locations_attributes][0][address][kind]'
  end

  def self.address_2
    'agency[organization][profile][office_locations_attributes][0][address][address_2]'
  end

  def self.city
    'agency[organization][profile][office_locations_attributes][0][address][city]'
  end

  def self.state
    'agency[organization][profile][office_locations_attributes][0][address][state]'
  end

  def self.zip
    'agency[organization][profile][office_locations_attributes][0][address][zip]'
  end

  def self.area_code
    'agency[organization][profile][office_locations_attributes][0][phone][area_code]'
  end

  def self.number
    'agency[organization][profile][office_locations_attributes][0][phone][number]'
  end

  def self.add_office_location_btn
    '#addOfficeLocation'
  end

  def self.create_broker_agency_btn
    '#broker-btn'
  end

  def self.registration_submitted_succesful_message
    'Thank you for submitting your request to access the broker account. Your application for access is pending'
  end
end