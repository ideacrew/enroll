module Forms
  class EmployeeDependent
    include ActiveModel::Model
    include ActiveModel::Validations

    attr_accessor :id, :family_id
    attr_accessor :gender, :relationship
    attr_writer :family
    include ::Forms::PeopleNames
    include ::Forms::SsnField
    include ::Forms::DateOfBirthField
    include Validations::USDate.on(:date_of_birth)

    validates_presence_of :first_name, :allow_blank => nil
    validates_presence_of :last_name, :allow_blank => nil
    validates_presence_of :gender, :allow_blank => nil
    validates_presence_of :family_id, :allow_blank => nil

    validates_inclusion_of :relationship, :in => ::PersonRelationship::Relationships, :allow_blank => nil

    def save
      return false unless valid?
      existing_inactive_family_member = family.find_matching_inactive_member(self)
      if existing_inactive_family_member
        self.id = existing_inactive_family_member.id
        existing_inactive_family_member.reactivate!(self.relationship)
        return true
      end
      existing_person = Person.match_existing_person(self)
      if existing_person
        family_member = family.relate_new_member(existing_person, self.relationship)
        self.id = family_member.id
        return true
      end
      person = Person.create!(extract_person_params)
      family_member = family.relate_new_member(person, self.relationship)
      self.id = family_member.id
      return true
    end

    def extract_person_params
      {
        :first_name => first_name,
        :last_name => last_name,
        :middle_name => middle_name,
        :name_pfx => name_pfx,
        :name_sfx => name_sfx,
        :gender => gender,
        :date_of_birth => date_of_birth,
        :ssn => ssn
      }
    end

    def persisted?
      !id.blank?
    end

    def family
      @family ||= Family.find(family_id)
    end

    def self.find(family_member_id)
      found_family_member = FamilyMember.find(family_member_id)
      self.new({
        :id => family_member_id,
        :family => found_family_member.family,
        :family_id => found_family_member.family_id,
        :first_name => found_family_member.first_name,
        :last_name => found_family_member.first_name,
        :middle_name => found_family_member.first_name,
        :name_pfx => found_family_member.name_pfx,
        :name_sfx => found_family_member.name_sfx,
        :date_of_birth => found_family_member.date_of_birth,
        :gender => found_family_member.gender,
        :ssn => found_family_member.ssn
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

    def update_attributes(attr)
      assign_attributes(attr)
      return false unless valid?
      return false unless family_member.person.update_attributes(extract_person_params)
      family_member.update_relationship(relationship)
    end
  end
end
