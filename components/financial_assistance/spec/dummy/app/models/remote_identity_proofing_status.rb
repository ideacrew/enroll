# frozen_string_literal: true

# This is a temporary fix for the fact that we have multiple ways and multiple
# bits of legacy data that check for RIDP in different ways.  Once we complete
# the migration and RIDP information comes only from ConsumerRole, we can
# replace all instances of this class usage.  It's abstracted into a class to
# make it easier to locate later and remove.
class RemoteIdentityProofingStatus
  def self.is_complete_for_person?(person)
    return false unless person
    return true if person.user&.identity_verified?

    person.consumer_role&.identity_verified?
  end

  def self.is_complete_for_consumer_role?(consumer_role)
    return false unless consumer_role
    return true if consumer_role.identity_verified?

    consumer_role.person.user&.identity_verified?
  end
end