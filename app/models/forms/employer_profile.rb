require 'date'
module Forms
  class EmployerProfile < SimpleDelegator
    extend ActiveModel::Naming
    WRAPPER_ATTRIBUTES = ["first_name", "last_name", "dob"]
    attr_accessor :first_name, :last_name
    attr_accessor :person
    attr_reader :dob

    class OrganizationAlreadyMatched < StandardError; end
    class PersonAlreadyMatched < StandardError; end
    class TooManyMatchingPeople < StandardError; end

    def dob=(val)
      @dob = Date.strptime(val,"%Y-%m-%d") rescue nil
    end

    def initialize(org)
      super(org)
      @errors = ActiveModel::Errors.new(self)
    end
  
    def self.human_attribute_name(attr, options = {})
      attr
    end

    def errors
      @full_errors ||= (
        organization.errors.each do |k, err|
          @errors.add(k, err)
        end
        @errors
      )
    end


    def self.model_name
      ::EmployerProfile.model_name
    end

    def self.build_blank(attrs={})
      new_form = self.new(Organization.new)
      new_form.build_employer_profile
      new_form.build_office_location
      new_form
    end

    def self.build(attrs = {})
      org_atts, wrapper_atts = pick_wrapper_attributes(attrs)
      new_form = self.new(check_existing_organization(org_atts))
      new_form.assign_wrapper_attributes(wrapper_atts)
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

    def bubble_employer_profile_errors
      bap = organization.broker_agency_profile
      organization.errors.delete(:employer_profile)
      bap.errors.each do |attr, err|
        organization.errors.add("employer_profile_attributes_#{attr}", err)
      end
    end

    def build_office_location
      self.class.build_office_location(__getobj__)
    end

    def self.build_office_location(org)
      org.office_locations.build unless org.office_locations.present?
      office_location = org.office_locations.first
      office_location.build_address unless office_location.address.present?
      office_location.build_phone unless office_location.phone.present?
    end

    def self.build_employer_profile(org)
      org.build_employer_profile unless org.employer_profile.present?
    end

    def build_employer_profile
      self.class.build_employer_profile(__getobj__)
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

    def self.check_existing_organization(attrs)
      new_organization = Organization.new(attrs)
      build_employer_profile(new_organization)
      build_office_location(new_organization)
      existing_org = Organization.where(:fein => new_organization.fein).first
      if existing_org.present?
        if existing_org.employer_profile.present?
          if (Person.where({:employer_staff_roles => { :employer_profile_id => existing_org.employer_profile._id }}).any?)
            new_organization.errors.add(:base, "a staff role for this organization has already been claimed.")
            return new_organization
          else
            existing_org.attributes = attrs
            return existing_org
          end
        else
          existing_org.build_employer_profile
          existing_org.attributes = attrs
          return existing_org
        end
      end
      new_org
    end

    def employer_profile
      organization.employer_profile
    end

    # TODO: Fix this to give broker agency staff role, not broker role
    def create_employer_staff_role(current_user, employer_staff)
      person.user = current_user
      person.broker_agency_staff_roles << EmployerStaffRole.new(:employer_profile => employer_profile)
      current_user.roles << "employer_staff" unless current_user.roles.include?("employer_staff")
    end

    def valid?(current_user)
      ["first_name", "last_name", "dob"].each do |prop|
        if self.send(prop).blank?
          @errors.add(prop.to_sym, "can not be blank")
        end
      end
      begin
        match_or_create_person(current_user)
      rescue TooManyMatchingPeople
        organization.errors.add(:base, "too many people match the criteria provided for your identity.  Please contact HBX.")
        valid_flag = false
      rescue PersonAlreadyMatched
        organization.errors.add(:base, "a person matching the provided personal information has already been claimed by another user.  Please contact HBX.")
      end

      (__getobj__.valid? && @errors.empty?).tap do 
        bubble_employer_profile_errors
      end
    end

    def save(current_user)
      return false unless valid?(current_user)
      organization.save!
      create_employer_staff_role(current_user, organization.employer_profile)
      true
    end

    def regex_for(str)
      Regexp.compile(Regexp.escape(str.to_s))
    end

  end
end
