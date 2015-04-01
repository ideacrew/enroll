module Parser
  class BrokerEmailParser
    include HappyMapper

    register_namespace 'xmlns', 'http://dchbx.dc.gov/broker'
    register_namespace 'ns1', 'http://dchbx.dc.gov/broker'

    tag 'email'

    namespace 'ns1'

    element :kind, String, xpath: 'ns1:parameters/ns1:type/ns1:text'
    element :address, String, xpath: 'ns1:text'

    def to_hash
      {
          kind: kind.downcase,
          address: address.downcase
      }
    end
  end
end
