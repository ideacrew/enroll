# frozen_string_literal: true

# This controller is responsible for the :new, :create, :show and :destroy actions of an consumer-embedded inbox
class Insured::InboxesController < InboxesController # rubocop:disable Style/ClassAndModuleChildren
  prepend_before_action :authorize_inbox_access

  def new
    @inbox_to_name = params['to']
    @inbox_provider_name = 'HBX ADMIN'
    super
  end

  def find_inbox_provider
    @inbox_provider_name = @inbox_provider.full_name
  end

  def successful_save_path
    exchanges_hbx_profiles_root_path
  end

  private

  def authorize_inbox_access
    # The family of the user associated with the inbox is needed to authorize access
    person = Person.find(params["id"])
    associated_family = person&.primary_family

    # We're using a FamilyPolicy method here because a modifying a Consumer/Employee/Resident Inbox has all of the same permissions as Family
    # All users/roles with the permissions to alter a Family should have the same permissions on the Inbox/Messages
    # While using a single :legacy_show? method from the family policy isn't ideal, it does cover a variety of unforseen edge cases that could emerge when determining access permissions for insured/inboxes
    authorize associated_family, :legacy_show?

    # We assign @inbox_provider here as to avoid making a duplicate call
    @inbox_provider = person
  end
end
