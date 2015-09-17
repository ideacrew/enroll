module Parsers::Xml::Cv
  class PersonDemographicsParser
    include HappyMapper

    tag 'person_demographics'

    element :ssn, String, tag: "ssn"
    element :sex, String, tag: "sex"
    element :birth_date, String, tag: "birth_date"
    element :death_date, String, tag: "death_date"
    element :ethnicity, String, tag: "ethnicity"
    element :race, String, tag: "race"
    element :marital_status, String, tag: "marital_status"
    element :citizen_status, String, tag: "citizen_status"
    element :is_state_resident, String, tag: "is_state_resident"
    element :is_incarcerated, String, tag: "is_incarcerated"

    def to_hash
      response = {
          ssn: ssn,
          sex: sex.split('#').last,
          birth_date: birth_date,
          is_state_resident:is_state_resident,
          citizen_status:citizen_status.split('#').last,
          marital_status:marital_status,
          death_date: death_date,
          race: race,
          ethnicity: ethnicity,
          is_incarcerated: is_incarcerated
      }
    end
  end
end
