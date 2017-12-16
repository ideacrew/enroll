module SponsoredBenefits
  class CensusMembers::CensusMember

    include Mongoid::Document
    include Mongoid::Timestamps
    include UnsetableSparseFields
    include SponsoredBenefits::Concerns::Ssn
    include SponsoredBenefits::Concerns::Dob
    include SponsoredBenefits::Concerns::Gender

    store_in collection: 'census_members'

    validates_with Validations::DateRangeValidator


    field :first_name, type: String
    field :middle_name, type: String
    field :last_name, type: String
    field :name_sfx, type: String

    include StrippedNames

    field :employee_relationship, type: String
    field :employer_assigned_family_id, type: String

    embeds_one :address
    accepts_nested_attributes_for :address, reject_if: :all_blank, allow_destroy: true

    embeds_one :email
    accepts_nested_attributes_for :email, allow_destroy: true

    validates_presence_of :first_name, :last_name, :employee_relationship

    def full_name
      [first_name, middle_name, last_name, name_sfx].compact.join(" ")
    end

  end
end
