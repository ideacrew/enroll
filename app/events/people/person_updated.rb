# frozen_string_literal: true

module People
  class PersonUpdated < EventSource::Event
    publisher_key 'people_publisher'

    contract_key 'validators.people.person_contract' 
    

  end
end
