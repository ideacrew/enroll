# frozen_string_literal: true

module BenefitSponsors
  # Policy used for auth in the BenefitSponsors app when running rspec from a GHA
  # For the time being there is no way to pass the GHAs without pulling from the BenefitSponsors
  # All "building blocks" have been select from existing methods in the main app ApplicationPolicy for ease of transition
  class ApplicationPolicy
    attr_reader :user, :record, :broker_agency_profile

    def initialize(user, record)
      @user = user
      @record = record
    end

    # Returns the user who is the account holder.
    #
    # @return [User] The user who is the account holder.
    def account_holder
      user
    end

    # Returns the person who is the account holder.
    # The method uses memoization to store the result of the first call to it and then return that result on subsequent calls,
    # instead of calling `account_holder.person` each time.
    #
    # @return [Person] The person who is the account holder.
    def account_holder_person
      return @account_holder_person if defined? @account_holder_person

      @account_holder_person = account_holder&.person
    end

    def hbx_role
      return @hbx_role if defined? @hbx_role

      @hbx_role = account_holder_person&.hbx_staff_role
    end

    def permission
      return @permission if defined? @permission

      @permission = hbx_role&.permission
    end

    def individual_market_admin?
      return false if hbx_role.blank?

      permission = hbx_role.permission
      return false if permission.blank?

      permission.modify_family
    end

    def shop_market_admin?
      # hbx_role = account_holder_person.hbx_staff_role
      # return false if hbx_role.blank?

      # permission = hbx_role.permission
      # return false if permission.blank?

      # permission.modify_employer
      individual_market_admin?
    end
  end
end
