# frozen_string_literal: true

module BenefitSponsors
  # Not currently being used -- policies should all inherit from the main app (::ApplicationPolicy)
  class ApplicationPolicy
    attr_reader :user, :record

    def initialize(user, record)
      @user = user
      @record = record
    end
  end
end
