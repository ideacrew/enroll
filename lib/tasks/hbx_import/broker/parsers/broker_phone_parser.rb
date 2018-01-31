module Parser
  class BrokerPhoneParser
    include HappyMapper

    register_namespace 'xmlns', 'http://dchbx.dc.gov/broker'
    register_namespace 'ns1', 'http://dchbx.dc.gov/broker'

    tag 'tel'

    namespace 'ns1'

    element :kind, String, xpath: 'ns1:parameters/ns1:type/ns1:text'
    element :full_phone_number, String, xpath: 'ns1:uri'

    def to_hash
      response = {
          kind: kind.downcase,
          full_phone_number: full_phone_number.split('tel:').last
      }
    end
  end
end
