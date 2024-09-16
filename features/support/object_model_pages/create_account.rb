# frozen_string_literal: true

#users/sign_up
class CreateAccount

  def self.email_or_username
    if EnrollRegistry[:bs4_consumer_flow].enabled?
      'user[oim_id]'
    else
      'user_oim_id'
    end
  end

  def self.password
    if EnrollRegistry[:bs4_consumer_flow].enabled?
      'user_password'
    else
      'user[password]'
    end
  end

  def self.password_confirmation
    if EnrollRegistry[:bs4_consumer_flow].enabled?
      'user_password_confirmation'
    else
      'user[password_confirmation]'
    end
  end

  def self.email
    if EnrollRegistry[:bs4_consumer_flow].enabled?
      'user_email'
    else
      'user[email]'
    end
  end

  def self.create_account_btn
    if EnrollRegistry[:bs4_consumer_flow].enabled?
      '#submit-button'
    else
      '.create-account-btn'
    end
  end

  def self.sign_in_link
    if EnrollRegistry[:bs4_consumer_flow].enabled?
      ''
    else
      '.btn-link'
    end
  end
end