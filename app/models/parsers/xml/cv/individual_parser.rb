module Parsers::Xml::Cv
  class IndividualParser
    include HappyMapper
    register_namespace 'ridp', 'http://openhbx.org/api/terms/1.0'
    namespace 'ridp'
    tag 'individual'

    element :id, String, :tag => 'id/ridp:id'
    has_one :person, Parsers::Xml::Cv::PersonParser, :tag => 'person', :namespace => 'ridp'
    has_one :person_demographics, Parsers::Xml::Cv::PersonDemographicsParser, :tag => 'person_demographics', :namespace => 'ridp'

    def to_hash
      response = {
          person: person.to_hash,
          person_demographics: person_demographics.to_hash
      }
      response[:id] = id.split('#').last if id
      response
    end
  end
end