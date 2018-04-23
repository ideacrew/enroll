module BenefitSponsors
  class Members::Member
    include Mongoid::Document
    include Mongoid::Timestamps

    GENDER_KINDS      = [:male, :female]
    RELATIONSHIP_MAP  = {
        :self                       => :self,
        :spouse                     => :spouse,
        :domestic_partner           => :domestic_partner,
        :child_under_26             => :child,
        :disabled_child_26_and_over => :disabled_child,
      }

    field :hbx_id,              type: String
    field :sponsor_assigned_id, type: String

    field :first_name,          type: String
    field :middle_name,         type: String
    field :last_name,           type: String
    field :name_sfx,            type: String

    field :encrypted_ssn,       type: String
    field :gender,              type: Symbol
    field :dob,                 type: Date

    field :relationship_to_primary_member,  type: Symbol
    field :sponsor_assigned_group_id,       type: String

    embeds_one  :address, 
                class_name: "BenefitSponsors::Locations::Address"
    embeds_one  :email, 
                class_name: "::Email"

    accepts_nested_attributes_for :address, 
                                  reject_if: :all_blank, 
                                  allow_destroy: true

    accepts_nested_attributes_for :email, 
                                  allow_destroy: true

    validate :birth_date_range

    def birth_date_range
      return unless dob.present?

      if dob > TimeKeeper.date_of_record
        errors.add(:dob, message: "future date: #{dob} is not valid for date of birth")
      end
      if (TimeKeeper.date_of_record.year - dob.year) > 110
        errors.add(:dob, message: "date of birth cannot be more than 110 years ago")
      end
    end

    validates :gender,
      allow_blank: true,
      allow_nil: true,
      inclusion: { in: GENDER_KINDS, message: "'%{value}' is not a valid gender kind" }

    validates :relationship_to_primary_member,
      presence: true,
      allow_blank: true,
      allow_nil:   true,
      inclusion: {
        in: RELATIONSHIP_MAP.keys,
        message: "'%{value}' is not a valid relationship kind"
      }

    def age_on(date = TimeKeeper.date_of_record)
      return unless dob.present?
      date.year - dob.year - ((date.month > dob.month || (date.month == dob.month && date.day >= dob.day)) ? 0 : 1)
    end

    def full_name
      [first_name, middle_name, last_name, name_sfx].compact.join(" ")
    end

    def gender=(new_gender)
      if new_gender.present?
        super(new_gender.to_s.downcase)
      else
        super(nil)
      end
    end

    def dob=(new_dob)
      if new_dob.is_a?(Date) || new_dob.is_a?(Time)
        super(new_dob)
      elsif new_dob.is_a?(String)
        transform_date = Date.strptime(new_dob, "%Y-%m-%d").to_date rescue nil
        super(transform_date)
      else
        super(nil)
      end
    end

    def is_primary_member?
      class_name_starts_with?(["employee", "survivor", "family"])
    end

    def is_dependent_member?
      class_name_starts_with?("dependent")
    end

    def is_survivor_member?
      class_name_starts_with?("survivor")
    end


    private

    # Case-insensitve match between start of this class name and compare_array
    def class_name_starts_with?(compare_array)
      self.class.to_s.demodulize.downcase.start_with?(compare_array)
    end


  end
end
