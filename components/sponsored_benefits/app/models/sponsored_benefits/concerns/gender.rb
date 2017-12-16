require 'active_support/concern'

module SponsoredBenefits
  module Concerns::Gender
    extend ActiveSupport::Concern
    
    GENDER_KINDS = %W(male female)

    included do
      field :gender, type: String

      validates :gender,
        allow_blank: false,
        inclusion: { in: GENDER_KINDS, message: "must be selected" }
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