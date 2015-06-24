module Forms
  class BrokerRole < ::Forms::PersonSignup
    include ActiveModel::Validations

    attr_accessor :broker_agency_profile
    attr_accessor :npn, :broker_agency_id

    validates_presence_of :npn

    validates :npn,
      length: { is: 9, message: "%{value} is not a valid NPN" },
      numericality: true


    class BrokerNpnAlreadyExists < StandardError; end
    class BrokerAgencyMissing < StandardError; end

    def self.model_name
      ::BrokerRole.model_name
    end

    def save
      return false unless valid?
      begin
        match_broker_agency
        match_broker_npn
        match_or_create_person
        person.save!
      rescue TooManyMatchingPeople
        errors.add(:base, "too many people match the criteria provided for your identity.  Please contact HBX.")
        return false
      rescue PersonAlreadyMatched
        errors.add(:base, "a person matching the provided personal information has already been claimed by another user.  Please contact HBX.")
        return false
      rescue BrokerAgencyMissing
        errors.add(:base, "please select your broker agency.")
        return false
      rescue BrokerNpnAlreadyExists
        errors.add(:base, "provided NPN has already been claimed by another broker.  Please contact HBX.")
        return false
      end

      person.broker_role = ::BrokerRole.new({ :provider_kind => 'broker', :npn => self.npn, :broker_agency_profile => broker_agency_profile })
      true
    end

    def match_broker_agency
      if self.broker_agency_id.blank?
        raise BrokerAgencyMissing.new
      end
      self.broker_agency_profile = ::BrokerAgencyProfile.find(self.broker_agency_id)
    end

    def match_broker_npn
      if Person.where("broker_role.npn" => npn).count > 0
        raise BrokerNpnAlreadyExists
      end
    end
  end
end
