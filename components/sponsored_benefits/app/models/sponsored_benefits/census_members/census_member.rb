module SponsoredBenefits
  class CensusMembers::CensusMember

    include Mongoid::Document
    include Mongoid::Timestamps
    include UnsetableSparseFields
    include SponsoredBenefits::Concerns::Ssn
    include SponsoredBenefits::Concerns::Dob

    store_in collection: 'census_members'

    validates_with Validations::DateRangeValidator

    GENDER_KINDS = %W(male female)

    field :first_name, type: String
    field :middle_name, type: String
    field :last_name, type: String
    field :name_sfx, type: String

    field :encrypted_ssn, type: String
    field :gender, type: String
    field :dob, type: Date

    include StrippedNames

    field :employee_relationship, type: String
    field :employer_assigned_family_id, type: String

    embeds_one :address
    accepts_nested_attributes_for :address, reject_if: :all_blank, allow_destroy: true

    embeds_one :email
    accepts_nested_attributes_for :email, allow_destroy: true

    validates_presence_of :first_name, :last_name, :dob, :employee_relationship

    validates :gender,
      allow_blank: false,
      inclusion: { in: GENDER_KINDS, message: "must be selected" }


    def full_name
      [first_name, middle_name, last_name, name_sfx].compact.join(" ")
    end

    def date_of_birth=(val)
      self.dob = Date.strptime(val, "%Y-%m-%d").to_date rescue nil
    end

    def gender=(val)
      if val.blank?
        write_attribute(:gender, nil)
        return
      end
      write_attribute(:gender, val.downcase)
    end

  end
end
