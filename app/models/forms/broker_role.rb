module Forms
  class BrokerRole < ::Forms::PersonSignup
    include ActiveModel::Validations

    attr_accessor :broker_agency_profile
    attr_accessor :npn, :broker_agency_id

    validates_presence_of :npn
    validate :broker_with_same_npn
    validate :broker_agency_presence

    validates :npn,
      length: { maximum: 10, message: "%{value} is not a valid NPN" },
      format: { with: /\A[1-9][0-9]+\z/, message: "%{value} is not a valid NPN" },
      numericality: true

    def self.model_name
      ::BrokerRole.model_name
    end

    def save
      return false unless valid?
      begin
        match_or_create_person
        person.save!
      rescue TooManyMatchingPeople
        errors.add(:base, "too many people match the criteria provided for your identity.  Please contact HBX.")
        return false
      rescue PersonAlreadyMatched
        errors.add(:base, "a person matching the provided personal information has already been claimed by another user.  Please contact HBX.")
        return false        
      end
      self.broker_agency_profile = ::BrokerAgencyProfile.find(self.broker_agency_id)
      person.broker_role = ::BrokerRole.new({ :provider_kind => 'broker', :npn => self.npn, :broker_agency_profile => broker_agency_profile })
      true
    end

    def broker_agency_presence
      if self.broker_agency_id.blank? || ::BrokerAgencyProfile.find(self.broker_agency_id).blank?
        errors.add(:base, "please select your broker agency.")
      end
    end

    def broker_with_same_npn
      if Person.where("broker_role.npn" => npn).count > 0
        errors.add(:base, "NPN has already been claimed by another broker. Please contact HBX.")
      end
    end
  end
end
