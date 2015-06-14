module Forms
  class BrokerAgencyProfile < SimpleDelegator
    WRAPPER_ATTRIBUTES = ["first_name", "last_name", "dob"]
    attr_accessor :first_name, :last_name, :dob
    attr_accessor :person

    class OrganizationAlreadyMatched < StandardError; end
    class PersonAlreadyMatched < StandardError; end
    class TooManyMatchingPeople < StandardError; end

    def initialize(org)
      super(org)
    end

    def self.model_name
      ::BrokerAgencyProfile.model_name
    end

    def self.build(attrs = {})
      org_atts, wrapper_atts = pick_wrapper_attributes(attrs)
      new_org = Organization.new
      new_org.build_broker_agency_profile
      new_org.attributes = org_atts
      new_form = self.new(new_org)
      new_form.build_office_location
      new_form.assign_wrapper_attributes(wrapper_atts)
      new_form
    end

    def self.pick_wrapper_attributes(atts = {})
      org_atts = {}
      wrapper_atts = {}
      atts.each_pair do |k, v|
        if WRAPPER_ATTRIBUTES.include?(k.to_s)
          wrapper_atts[k] = v
        else
          org_atts[k] = v
        end
      end
      [org_atts, wrapper_atts]
    end

    def assign_wrapper_attributes(attrs = {})
      attrs.each_pair do |k,v|
        self.send("#{k}=", v)
      end
    end

    def organization
      __getobj__
    end

    def bubble_broker_agency_profile_errors
      bap = organization.broker_agency_profile
      organization.errors.delete(:broker_agency_profile)
      bap.errors.each do |attr, err|
        organization.errors.add("broker_agency_profile_attributes_#{attr}", err)
      end
    end

    def build_office_location
      __getobj__.office_locations.build unless organization.office_locations.present?
      office_location = organization.office_locations.first
      office_location.build_address unless office_location.address.present?
      office_location.build_phone unless office_location.phone.present?
    end

    def build_broker_agency_profile
      __getobj__.build_broker_agency_profile unless __getobj__.broker_agency_profile.present?
    end

    def match_or_create_person(current_user)
      new_person =   Person.new({
          :first_name => first_name,
          :last_name => last_name,
          :dob => dob
      })
      matched_people = Person.where(
        first_name: regex_for(first_name),
        last_name: regex_for(first_name),
        dob: new_person.dob
      )
      if matched_people.count > 1
        raise TooManyMatchingPeople.new
      end
      if matched_people.count == 1
        mp = matched_people.first
        if mp.user.present?
          if mp.user.id.to_s != current_user.id
            raise PersonAlreadyMatched.new
          end
        end
        self.person = mp
      else
        self.person = new_person
      end
    end

    def check_existing_organization
      fein_value = organization.fein
      existing_org = Organization.where(:fein => fein_value).first
      if existing_org.present?
        raise OrganizationAlreadyMatched.new
      end
    end

    def broker_agency_profile
      organization.broker_agency_profile
    end

    # TODO: Fix this to give broker agency staff role, not broker role
    def create_broker_agency_staff_role(current_user, broker_agency_profile)
      person.user = current_user
      person.broker_agency_staff_roles << BrokerAgencyStaffRole.new(:broker_agency_profile => broker_agency_profile)
      current_user.roles << "broker" unless current_user.roles.include?("broker")
    end

    def valid?(current_user)
      valid_flag = true
      ["first_name", "last_name", "dob"].each do |prop|
        if self.send(prop).blank?
          organization.errors.add(prop, "can not be blank")
          valid_flag = false
        end
      end
      begin
        match_or_create_person(current_user)
      rescue TooManyMatchingPeople
        organization.errors.add(:base, "too many people match the criteria provided for your identity.  Please contact HBX.")
        valid_flag = false
      rescue PersonAlreadyMatched
        organization.errors.add(:base, "a person matching the provided personal information has already been claimed by another user.  Please contact HBX.")
        valid_flag = false
      end

      begin
        check_existing_organization
      rescue OrganizationAlreadyMatched
        organization.errors.add(:base, "a staff role for this organization has already been claimed.")
        valid_flag = false
      end
      (__getobj__.valid? && valid_flag).tap do 
        bubble_broker_agency_profile_errors
      end
    end

    def save(current_user)
      return false unless valid?(current_user)
      organization.save!
      create_broker_agency_staff_role(current_user, organization.broker_agency_profile)
      true
    end

    def regex_for(str)
      Regexp.compile(Regexp.escape(str.to_s))
    end

  end
end
