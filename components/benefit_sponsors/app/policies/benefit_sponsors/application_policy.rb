module BenefitSponsors
  class ApplicationPolicy
    attr_reader :user, :record

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

      @account_holder_person = account_holder.person
    end

    def hbx_role
      return @hbx_role if defined? @hbx_role
  
      @hbx_role = account_holder_person&.hbx_staff_role
    end
  end
end
