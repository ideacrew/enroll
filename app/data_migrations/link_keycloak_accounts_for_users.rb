# frozen_string_literal: true

require File.join(Rails.root, 'lib/mongoid_migration_task')
require 'dry/monads'
require 'dry/monads/do'
# This migration is for creating keycloak accounts for existing users and updating users with keycloak account ids.
class LinkKeycloakAccountsForUsers < MongoidMigrationTask
  include Dry::Monads[:result, :do, :try]

  def migrate
    headless_users = User.exists(account_id: false)

    headless_users.no_timeout.each do |user|
      user_values = {
        username: user.oim_id,
        password: 'ChangeMe!!',
        email: user.email,
        first_name: user&.person&.first_name,
        last_name: user&.person&.last_name,
        attributes: {
          enroll_role: user.roles.first,
          relay_state: relay_state_for(user)
        }
      }

      Try() { Operations::Accounts::Create.new.call(account: user_values) }
        .to_result
        .bind do |account|
          if account.success?
            account_attrs = account.success
            user.account_id = user.oim_id = account_attrs[:user][:id]
            user.save
          else
            Rails
              .logger.debug "Failed to create account for user oim_id: #{user.oim_id} email: #{user.email} due to #{account.failure.errors.to_h}"
          end
        end
    end
  end

  private

  def relay_state_for(user)
    if user.roles.include?('broker')
      '/benefit_sponsors/profiles/registrations/new?portal=true&profile_type=broker_agency'
    elsif user.roles.include?('hbx_staff')
      '/exchanges/hbx_profiles'
    end
  end
end
