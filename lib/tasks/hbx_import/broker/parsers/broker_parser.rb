require_relative './broker_phone_parser'
require_relative './broker_email_parser'
require_relative './broker_address_parser'

module Parser
  class BrokerParser
    include HappyMapper

    register_namespace 'xmlns', 'http://dchbx.dc.gov/broker'
    register_namespace 'ns1', 'http://dchbx.dc.gov/broker'

    tag 'broker'

    namespace 'ns1'

    element :npn, String, tag: 'npn'
    element :license_number, String, xpath: 'ns1:license/ns1:license_number'
    element :state, String, xpath: 'ns1:license/ns1:state'
    element :first_name, String, xpath: 'ns1:vcard/ns1:n/ns1:given'
    element :last_name, String, xpath: 'ns1:vcard/ns1:n/ns1:surname'
    element :full_name, String, xpath: 'ns1:vcard/ns1:fn'
    element :organization, String, xpath: 'ns1:vcard/ns1:org'
    element :exchange_id, String, tag: 'element'
    element :exchange_status, String, tag: 'exchange_status'
    element :associated_agency_name, String, tag: 'associated_agency_name'
    element :associated_agency_fein, String, tag: 'associated_agency_fein'
    has_many :phones, Parser::BrokerPhoneParser, xpath: 'ns1:vcard'
    has_many :emails, Parser::BrokerEmailParser, xpath: 'ns1:vcard'
    has_many :addresses, Parser::BrokerAddressParser, xpath: 'ns1:vcard'

    def to_hash
      {
          npn: npn,
          license_number: license_number,
          state: state,
          name: {
              first_name: first_name,
              last_name: last_name,
              full_name: full_name
          },
          phones: phones.map(&:to_hash),
          emails: emails.map(&:to_hash),
          addresses: addresses.map(&:to_hash),
          exchange_id: exchange_id,
          exchange_status: exchange_status,
          organization_name: organization
      }
    end
  end
end
