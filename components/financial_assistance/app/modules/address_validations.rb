# frozen_string_literal: true

# This module is for addresses validations
module AddressValidations
  def has_in_state_home_addresses?(addresses_attributes)
    symbolize_addresses_attributes = addresses_attributes&.deep_symbolize_keys
    home_address = symbolize_addresses_attributes&.select{|_k, address| address[:kind] == 'home' && address[:state] == EnrollRegistry[:enroll_app].setting(:state_abbreviation).item}
    home_address.present?
  end
end
