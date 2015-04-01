module Parser
  class BrokerAddressParser
    include HappyMapper

    register_namespace 'xmlns', 'http://dchbx.dc.gov/broker'
    register_namespace 'ns1', 'http://dchbx.dc.gov/broker'

    tag 'adr'

    namespace 'ns1'

    element :kind, String, xpath: 'ns1:parameters/ns1:type/ns1:text'
    element :street, String, xpath: 'ns1:street'
    element :locality, String, xpath: 'ns1:locality'
    element :region, String, xpath: 'ns1:region'
    element :code, String, xpath: 'ns1:code'
    element :country, String, xpath: 'ns1:country'

    def to_hash
      {
          kind: kind.downcase,
          street: street,
          locality: locality,
          region: region,
          code: code,
          country: country
      }
    end
  end
end
