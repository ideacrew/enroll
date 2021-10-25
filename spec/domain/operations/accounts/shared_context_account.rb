# frozen_string_literal: true

RSpec.shared_context 'account' do
  let(:avengers) do
    {
      black_panther: {
        username: 'black_panther',
        password: '$3cr3tP@55w0rd',
        email: 'black_panther@avengers.org',
        first_name: "T'Challa",
        last_name: 'Wakandason'
      },
      iron_man: {
        username: 'iron_man',
        password: '$3cr3tP@55w0rd',
        email: 'iron_man@avengers.org',
        first_name: 'Tony',
        last_name: 'Stark'
      },
      captain_america: {
        username: 'captain_america',
        password: '$3cr3tP@55w0rd',
        email: 'captain_america@avengers.org',
        first_name: 'Steve',
        last_name: 'Rodgers'
      },
      black_widow: {
        username: 'black_widow',
        password: '$3cr3tP@55w0rd',
        email: 'black_widow@avengers.org',
        first_name: 'Natasha',
        last_name: 'Romanoff'
      },
      thor: {
        username: 'thor',
        password: '$3cr3tP@55w0rd',
        email: 'thor@avengers.org',
        first_name: 'Thor',
        last_name: 'Odinson'
      },
      doctor_strange: {
        username: 'doctor_strange',
        password: '$3cr3tP@55w0rd',
        email: 'doctor_strange@avengers.org',
        first_name: 'Steven',
        last_name: 'Strange'
      }
    }
  end

  def create_avenger_accounts
    avengers.each { |_k, v| Operations::Accounts::Create.new.call(account: v) }
  end

  def delete_avenger_accounts
    avengers.each do |_k, v|
      Operations::Accounts::Delete.new.call(login: v[:username])
    end
  end

  # rubocop:disable Metrics/MethodLength
  def find_all_stub
    [
      {
        id: '6304e375-c5f6-45c4-bd9c-da75b01d19f4',
        created_at: '2021-10-21 19:46:26 +0000',
        username: 'black_panther',
        enabled: true,
        totp: false,
        email_verified: false,
        first_name: "T'Challa",
        last_name: 'Wakandason',
        email: 'black_panther@avengers.org',
        disableable_credential_types: [],
        required_actions: [],
        not_before: 0,
        access: {
          manage_group_membership: true,
          view: true,
          map_roles: true,
          impersonate: false,
          manage: true
        }
      },
      {
        id: 'd5164104-0243-4752-8985-4dd965af7db7',
        created_at: '2021-10-21 19:46:27 +0000',
        username: 'black_widow',
        enabled: true,
        totp: false,
        email_verified: false,
        first_name: 'Natasha',
        last_name: 'Romanoff',
        email: 'black_widow@avengers.org',
        disableable_credential_types: [],
        required_actions: [],
        not_before: 0,
        access: {
          manage_group_membership: true,
          view: true,
          map_roles: true,
          impersonate: false,
          manage: true
        }
      },
      {
        id: '02eb8942-5b7a-4eba-9b39-fb6c13629da8',
        created_at: '2021-10-21 19:46:27 +0000',
        username: 'captain_america',
        enabled: true,
        totp: false,
        email_verified: false,
        first_name: 'Steve',
        last_name: 'Rodgers',
        email: 'captain_america@avengers.org',
        disableable_credential_types: [],
        required_actions: [],
        not_before: 0,
        access: {
          manage_group_membership: true,
          view: true,
          map_roles: true,
          impersonate: false,
          manage: true
        }
      },
      {
        id: '6e0d79f2-1667-4074-a75d-e1eaa574ea78',
        created_at: '2021-10-21 19:46:28 +0000',
        username: 'doctor_strange',
        enabled: true,
        totp: false,
        email_verified: false,
        first_name: 'Steven',
        last_name: 'Strange',
        email: 'doctor_strange@avengers.org',
        disableable_credential_types: [],
        required_actions: [],
        not_before: 0,
        access: {
          manage_group_membership: true,
          view: true,
          map_roles: true,
          impersonate: false,
          manage: true
        }
      },
      {
        id: 'b6db09ea-5b30-495e-ada6-56622e925c25',
        created_at: '2021-10-21 19:46:26 +0000',
        username: 'iron_man',
        enabled: true,
        totp: false,
        email_verified: false,
        first_name: 'Tony',
        last_name: 'Stark',
        email: 'iron_man@avengers.org',
        disableable_credential_types: [],
        required_actions: [],
        not_before: 0,
        access: {
          manage_group_membership: true,
          view: true,
          map_roles: true,
          impersonate: false,
          manage: true
        }
      },
      {
        id: '56b61bd2-270e-4e99-9f23-823f7840701c',
        created_at: '2021-10-21 19:46:28 +0000',
        username: 'thor',
        enabled: true,
        totp: false,
        email_verified: false,
        first_name: 'Thor',
        last_name: 'Odinson',
        email: 'thor@avengers.org',
        disableable_credential_types: [],
        required_actions: [],
        not_before: 0,
        access: {
          manage_group_membership: true,
          view: true,
          map_roles: true,
          impersonate: false,
          manage: true
        }
      }
    ]
  end
  # rubocop:enable Metrics/MethodLength

  # Actions
  # Lock/Unlock Account
  # Reset Password - set to value
  # Forgot Password - set a flag in required actions
  # Edit User
  def ui_index_page_row_stub
    accounts = Operations::Accounts.Find(scope_name: :all, page: 1, page_size: 20)
    User.where(
      :account_id.in =>
        accounts.reduce([]) { |ids, account| ids << account[:id] }
    )

    # {
    #     accounts = {
    #       id: 'b6db09ea-5b30-495e-ada6-56622e925c25',
    #       username: 'iron_man',
    #       email: 'iron_man@avengers.org',
    #       enabled: true,
    #       required_actions: [], # password reset is pending
    #     user: {
    #       id: 'b6db09ea-5b30-495e-ada6-56622e925c25',
    #       role_type: role_type,
    #       person: {
    #         ssn: ssn,
    #         dob: dob,
    #         hbx_id: hbx_id,
    #       #   first_name: 'Tony',
    #       #   last_name: 'Stark'
    #       # login_history: login_history,
    #       # permission_level: permission_level,
    #       }
    #       }
    #     }
  end

  def ui_attributes_unused
    {
      created_at: '2021-10-21 19:46:26 +0000',
      totp: false,
      email_verified: false,
      disableable_credential_types: [],
      not_before: 0,
      access: {
        manage_group_membership: true,
        view: true,
        map_roles: true,
        impersonate: false,
        manage: true
      }
    }
  end
end
