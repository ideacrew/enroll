module Forms
  class BrokerCandidate < ::Forms::PersonSignup
    include ActiveModel::Validations
    include PeopleNames
    include NpnField

    attr_accessor :application_type, :email, :broker_agency_id, :broker_agency_type, :broker_applicant_type

    validates_presence_of :first_name, :allow_blank => nil
    validates_presence_of :last_name, :allow_blank => nil
    validate :broker_agency_presence

    validates_presence_of :npn, if: :broker_role?
    validate :broker_with_same_npn, if: :broker_role?
    validates :npn,
      length: { maximum: 10, message: "%{value} is not a valid NPN" },
      format: { with: /\A[1-9][0-9]+\z/, message: "%{value} is not a valid NPN" },
      numericality: true,
      if: :broker_role?

    def broker_role?
      self.broker_applicant_type == 'staff' ? false : true
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

      broker_agency_profile = ::BrokerAgencyProfile.find(self.broker_agency_id)
      if broker_role?
        person.broker_role = ::BrokerRole.new( { 
            :provider_kind => 'broker', 
            :npn => self.npn, 
            :broker_agency_profile => broker_agency_profile 
            })
      else
        person.broker_agency_staff_roles << ::BrokerAgencyStaffRole.new(:broker_agency_profile => broker_agency_profile)
      end

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
