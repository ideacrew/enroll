module Parsers::Xml::Cv
  class HavenPersonDemographicsParser
    include HappyMapper

    register_namespace 'ridp', 'http://openhbx.org/api/terms/1.0'
    tag 'person_demographics'
    namespace 'ridp'

    element :ssn, String, tag: "ssn"
    element :sex, String, tag: "sex"
    element :birth_date, String, tag: "birth_date"
    # element :death_date, String, tag: "death_date"
    # element :ethnicity, String, tag: "ethnicity"
    # element :race, String, tag: "race"
    # element :marital_status, String, tag: "marital_status"
    # element :citizen_status, String, tag: "citizen_status"
    # element :is_state_resident, Boolean, tag: "is_state_resident"
    # element :is_incarcerated, Boolean, tag: "is_incarcerated"

            # <n1:person_demographics>
            #     <n1:ssn>294120001</n1:ssn>
            #     <n1:sex>urn:openhbx:terms:v1:gender#male</n1:sex>
            #     <n1:birth_date>19700601</n1:birth_date>
            # </n1:person_demographics>


    # def to_hash
    #   sex_value = sex.blank? ? nil : sex.split('#').last
    #   cs_value = citizen_status.blank? ? nil  : citizen_status.split('#').last
    #   response = {
    #       ssn: ssn,
    #       sex: sex_value,
    #       birth_date: birth_date,
    #       is_state_resident: is_state_resident,
    #       citizen_status: cs_value,
    #       marital_status: marital_status,
    #       death_date: death_date,
    #       race: race,
    #       ethnicity: ethnicity,
    #       is_incarcerated: is_incarcerated
    #   }
    # end
  end
end
