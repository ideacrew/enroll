require 'active_support/concern'

module SponsoredBenefits
  module Concerns::Dob
    extend ActiveSupport::Concern

    included do
      field :dob, type: Date

      validates_presence_of :dob
      validate :date_of_birth_is_past
    end

    def dob_string
      self.dob.blank? ? "" : self.dob.strftime("%Y%m%d")
    end

    def date_of_birth
      self.dob.blank? ? nil : self.dob.strftime("%m/%d/%Y")
    end

    def date_of_birth=(val)
      self.dob = Date.strptime(val, "%Y-%m-%d").to_date rescue nil
    end

    def date_of_birth_is_past
      return unless self.dob.present?
      errors.add(:dob, "future date: #{self.dob} is invalid date of birth") if TimeKeeper.date_of_record < self.dob
    end

    def age_on(date)
      age = date.year - dob.year
      if date.month == dob.month
        age -= 1 if date.day < dob.day
      else
        age -= 1 if date.month < dob.month
      end
      age
    end
  end
end