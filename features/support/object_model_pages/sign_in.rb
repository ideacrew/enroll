# frozen_string_literal: true

class SignIn

  def self.username
    'user_login'
  end

  def self.password
    'user[password]'
  end

  def self.remember_me_checkbox
    '#user_remember_me'
  end

  def self.sign_in_btn
    '.sign-in-btn'
  end

  def self.forgot_your_password_btn
    '//a[contains(text(), "Forgot your password?")]'
  end

  def self.create_account_btn
    '//a[contains(text(), "Create account")]'
  end
end
