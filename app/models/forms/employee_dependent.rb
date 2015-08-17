module Forms
  class EmployeeDependent
    include ActiveModel::Model
    include ActiveModel::Validations

    attr_accessor :id, :family_id, :is_consumer_role
    attr_accessor :gender, :relationship
    attr_writer :family
    include ::Forms::PeopleNames
    include ::Forms::ConsumerFields
    include ::Forms::SsnField
    #include ::Forms::DateOfBirthField
    #include Validations::USDate.on(:date_of_birth)

    validates_presence_of :first_name, :allow_blank => nil
    validates_presence_of :last_name, :allow_blank => nil
    validates_presence_of :gender, :allow_blank => nil
    validates_presence_of :family_id, :allow_blank => nil
    validates_presence_of :dob
    validates_inclusion_of :relationship, :in => ::PersonRelationship::Relationships, :allow_blank => nil
    validate :relationship_validation

    attr_reader :dob

    def dob=(val)
      @dob = Date.strptime(val, "%Y-%m-%d") rescue nil
    end

    def save
      return false unless valid?
      existing_inactive_family_member = family.find_matching_inactive_member(self)
      if existing_inactive_family_member
        self.id = existing_inactive_family_member.id
        existing_inactive_family_member.reactivate!(self.relationship)
        existing_inactive_family_member.save!
        return true
      end
      existing_person = Person.match_existing_person(self)
      if existing_person
        family_member = family.relate_new_member(existing_person, self.relationship)
        family_member.family.build_consumer_role(family_member) if self.is_consumer_role == "true"
        family_member.save!
        self.id = family_member.id
        return true
      end
      person = Person.new(extract_person_params)
      return false unless try_create_person(person)
      family_member = family.relate_new_member(person, self.relationship)
      family_member.family.build_consumer_role(family_member) if self.is_consumer_role == "true"
      family.save!
      self.id = family_member.id
      true
    end

    def try_create_person(person)
      person.save.tap do
        bubble_person_errors(person)
      end
    end

    def extract_person_params
      {
        :first_name => first_name,
        :last_name => last_name,
        :middle_name => middle_name,
        :name_pfx => name_pfx,
        :name_sfx => name_sfx,
        :gender => gender,
        :dob => dob,
        :ssn => ssn,
        :race => race,
        :ethnicity => ethnicity,
        :language_code => language_code,
        :is_tobacco_user => is_tobacco_user,
        :is_incarcerated => is_incarcerated,
        :is_disabled => is_disabled
      }
    end

    def persisted?
      !id.blank?
    end

    def destroy!
      family.remove_family_member(family_member.person)
      family.save!
    end

    def family
      @family ||= Family.find(family_id)
    end

    def self.find(family_member_id)
      found_family_member = FamilyMember.find(family_member_id)
      self.new({
        :relationship => found_family_member.primary_relationship,
        :id => family_member_id,
        :family => found_family_member.family,
        :family_id => found_family_member.family_id,
        :first_name => found_family_member.first_name,
        :last_name => found_family_member.last_name,
        :middle_name => found_family_member.middle_name,
        :name_pfx => found_family_member.name_pfx,
        :name_sfx => found_family_member.name_sfx,
        :dob => (found_family_member.dob.is_a?(Date) ? found_family_member.dob.try(:strftime, "%Y-%m-%d") : found_family_member.dob),
        :gender => found_family_member.gender,
        :ssn => found_family_member.ssn,
        :race => found_family_member.race,
        :ethnicity => found_family_member.ethnicity,
        :language_code => found_family_member.language_code,
        :is_tobacco_user => found_family_member.is_tobacco_user,
        :is_incarcerated => found_family_member.is_incarcerated,
        :is_disabled => found_family_member.is_disabled,
      })
    end

    def family_member
      @family_member = FamilyMember.find(id)
    end

    def assign_attributes(atts)
      atts.each_pair do |k, v|
        self.send("#{k}=".to_sym, v)
      end
    end

    def bubble_person_errors(person)
      if person.errors.has_key?(:ssn)
        person.errors.get(:ssn).each do |err|
          self.errors.add(:ssn, err)
        end
      end
    end

    def try_update_person(person)
      person.update_attributes(extract_person_params).tap do
        bubble_person_errors(person)
      end
    end

    def update_attributes(attr)
      assign_attributes(attr)
      return false unless valid?
      return false unless try_update_person(family_member.person)
      family_member.family.build_consumer_role(family_member) if attr["is_consumer_role"] == "true"
      family_member.update_relationship(relationship)
      family_member.save!
      true
    end


    def relationship_validation
      return if family.blank? or family.family_members.blank?

      relationships = Hash.new
      family.active_family_members.each{|fm| relationships[fm._id.to_s]=fm.relationship}
      relationships[self.id.to_s] = self.relationship
      if relationships.values.count{|rs| rs=='spouse' || rs=='life_partner'} > 1
        self.errors.add(:base, "can not have multiple spouse or life partner")
      end
    end
  end
end
