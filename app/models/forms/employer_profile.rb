require 'date'
module Forms
  class EmployerProfile 
    include ActiveModel::Validations
    attr_accessor :id
    attr_accessor :first_name, :last_name
    attr_accessor :legal_name, :dba, :entity_kind, :fein
    attr_reader :dob
    attr_reader :office_locations
    attr_accessor :person
    attr_reader :employer_profile

      validates :fein,
            length: { is: 9, message: "%{value} is not a valid FEIN" },
                numericality: true
    validates_presence_of :dob, :first_name, :last_name, :fein, :legal_name
    validates :entity_kind,
        inclusion: { in: ::Organization::ENTITY_KINDS, message: "%{value} is not a valid business entity kind" },
        allow_blank: false

    validate :office_location_validations

    def to_key
      @id
    end

    def office_location_validations
      @office_locations.each_with_index do |ol, idx|
         ol.errors.each do |k, v|
           self.errors.add("office_locations_attributes.#{idx}.#{k}", v) 
         end
      end
    end


    class OrganizationAlreadyMatched < StandardError; end
    class PersonAlreadyMatched < StandardError; end
    class TooManyMatchingPeople < StandardError; end

    def office_locations_attributes
      @office_locations.map do |office_location|
        office_location.attributes
      end
    end

    def office_locations_attributes=(attrs)
      attrs.each_pair do |k, att_set|
        @office_locations << OfficeLocation.new(att_set)
      end
    end

    def dob=(val)
      @dob = Date.strptime(val,"%Y-%m-%d") rescue nil
    end

    def initialize(attrs = {})
      @office_locations ||= []
      assign_wrapper_attributes(attrs)
      ensure_office_locations
    end

    def assign_wrapper_attributes(attrs = {})
      attrs.each_pair do |k,v|
        self.send("#{k}=", v)
      end
    end

    def ensure_office_locations
      if @office_locations.empty?
        new_office_location = OfficeLocation.new
        new_office_location.build_address
        new_office_location.build_phone
        @office_locations = [new_office_location]
      end
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
      existing_org = Organization.where(:fein => fein).first
      if existing_org.present?
        if existing_org.employer_profile.present?
          if (Person.where({:employer_staff_roles => { :employer_profile_id => existing_org.employer_profile._id }}).any?)
            raise OrganizationAlreadyMatched.new
          end
        end
        return existing_org
      end
      nil
    end

    # TODO: Fix this to give broker agency staff role, not broker role
    def create_employer_staff_role(current_user, employer_profile)
      person.user = current_user
      person.employer_staff_roles << EmployerStaffRole.new(:employer_profile_id => employer_profile.id)
      current_user.roles << "employer_staff" unless current_user.roles.include?("employer_staff")
      current_user.save!
    end

    def save(current_user)
      return false unless valid?
      begin
        match_or_create_person(current_user)
        person.save!
      rescue TooManyMatchingPeople
        errors.add(:base, "too many people match the criteria provided for your identity.  Please contact HBX.")
        return false
      rescue PersonAlreadyMatched
        errors.add(:base, "a person matching the provided personal information has already been claimed by another user.  Please contact HBX.")
        return false
      end
      existing_org = nil
      begin
        existing_org = check_existing_organization
      rescue OrganizationAlreadyMatched
            errors.add(:base, "a staff role for this organization has already been claimed.")
            return false
      end
      employer_profile = nil
      if existing_org
        update_organization(existing_org)
        employer_profile = existing_org.employer_profile
      else
        org = create_new_organization
        @employer_profile = org.employer_profile
      end
      create_employer_staff_role(current_user, @employer_profile)
      true
    end

    def create_new_organization
      Organization.create!(
        :fein => fein,
        :legal_name => legal_name,
        :dba => dba,
        :employer_profile => ::EmployerProfile.new({
          :entity_kind => entity_kind
        }),
        :office_locations => office_locations
      )
    end

    def update_organization(org)
      if !org.employer_profile.present?
        org.create_employer_profile({:entity_kind => entity_kind})
        org.save!
      end
    end

    def regex_for(str)
      Regexp.compile(Regexp.escape(str.to_s))
    end

  end
end
