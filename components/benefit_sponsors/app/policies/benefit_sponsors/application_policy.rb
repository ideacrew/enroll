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

      @account_holder_person = account_holder&.person
    end

    # Returns active broker_role of account holder, if present
    #
    # @return [BrokerRole]
    def broker_role
      @broker_role ||= account_holder_person.broker_role if account_holder_person&.broker_role&.active?
    end

    # Returns an array of broker_staff_roles of account holder, if present
    #
    # @return Array([BrokerStaffRoles])
    def broker_staff_roles
      @staff_roles ||= account_holder_person&.active_broker_staff_roles
    end

    # Determines if the current user has an hbx_staff_role with a permission
    #
    # @return [Permission], which can then have the relevant attr checked
    def hbx_staff_role_permission
      @hbx_staff_role_permission ||= retrieve_account_holder_hbx_staff_role_permission
    end

    def retrieve_account_holder_hbx_staff_role_permission
      hbx_role = account_holder_person&.hbx_staff_role
      return false if hbx_role.blank?

      permission = hbx_role&.permission
      return false if permission.blank?

      permission
    end
  end
end
