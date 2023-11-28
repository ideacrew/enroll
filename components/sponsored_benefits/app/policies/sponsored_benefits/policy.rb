# frozen_string_literal: true

module SponsoredBenefits
  # This class is base policy class
  class Policy

    attr_reader :user, :record

    def initialize(user, record)
      @user = user
      @record = record
    end


    # Include Policy Scope
  end
end
