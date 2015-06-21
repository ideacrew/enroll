module Forms
  class BrokerCandidate
    include ActiveModel::Model
    include ActiveModel::Validations

    include PeopleNames
    attr_accessor :application_type, :email, :broker_agency_id, :broker_agency_type, :broker_applicant_type

    validates_presence_of :first_name, :allow_blank => nil
    validates_presence_of :last_name, :allow_blank => nil

    include ::Forms::DateOfBirthField
    include Validations::USDate.on(:date_of_birth)

    include NpnField
  end
end
