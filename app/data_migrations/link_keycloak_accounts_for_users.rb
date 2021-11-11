# frozen_string_literal: true

require File.join(Rails.root, 'lib/mongoid_migration_task')
require 'dry/monads'
require 'dry/monads/do'
# This migration is for creating keycloak accounts for existing users and updating users with keycloak account ids.
class LinkKeycloakAccountsForUsers < MongoidMigrationTask
  include Dry::Monads[:result, :do, :try]
  include Rails.application.routes.url_helpers
  include BenefitSponsors::Engine.routes.url_helpers

  # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity, Metrics/AbcSize
  def migrate
    User.all.no_timeout.each do |user|
      user_values = {
        username: user.oim_id,
        password: 'ChangeMe1!!',
        email: user.email,
        first_name: user&.person&.first_name,
        last_name: user&.person&.last_name,
        realm_roles: user.roles
      }
      result = Operations::Accounts::Create.new.call(account: user_values)
      result = Operations::Accounts::GetUser.new.call(user.account_id) if result.failure? && user.account_id
      result = Operations::Accounts::Find.new.call(scope_name: :by_username, criterion: user.oim_id) if result.failure?
      result = Operations::Accounts::Find.new.call(scope_name: :by_email, criterion: user.email) if result.blank?

      puts "Couldn't find or create a user for ID: #{user.id} #{user.email} #{user.oim_id}" unless result

      account_attrs = result.value_or(result.failure)
      account_attrs = account_attrs.first if account_attrs.is_a?(Array) # result from line 26 or 27
      account_attrs = account_attrs[:user] if account_attrs.key?(:user) # result from line 24
      if account_attrs.is_a?(Hash) && account_attrs.deep_symbolize_keys![:id]
        user.account_id = account_attrs[:id]

        Operations::Accounts::Update.new.call(
          account: {
            id: user.account_id,
            attributes: {
              id: user.account_id,
              relay_state: relay_state_for(user)
            }
          }
        )
        Operations::Accounts::AddToRole.new.call(id: account_attrs[:id], roles: user.roles) if user.roles
        user.set(account_id: account_attrs[:id])
        # add_user_to_keycloak_group(user)
      else
        Rails
          .logger.debug "Failed to create or find account for user oim_id: #{user.oim_id} email: #{user.email} due to #{result.failure}"
      end
    end
  end
  # rubocop:enable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity, Metrics/AbcSize

  private

  def relay_state_for(user)
    if user.roles&.include?('broker')
      broker_agency_profile = user.person.broker_role.broker_agency_profile
      profiles_broker_agencies_broker_agency_profile_path(broker_agency_profile)
    elsif user.roles&.include?('hbx_staff')
      '/exchanges/hbx_profiles'
    end
  end

  def add_user_to_keycloak_group(user)
    group_name = 'hbx_staff' if user.roles.include?('hbx_staff')
    group_name = 'broker' if user.roles.include?('broker')
    return Success('no group needed') unless group_name
    result =
      Operations::Accounts::AddToGroup.new.call(
        group: group_name,
        user_id: user.account_id
      )

    Rails.logger.debug "Failed to add group for user #{user.email} group #{group_name} due to #{result.failure}" if result.failure?
  end
end
