# frozen_string_literal: true

class VerifyIdentity

  include RSpec::Matchers
  include Capybara::DSL

  def pick_answer_a
    '//label[@for="interactive_verification_questions_attributes_0_response_id_a"]//span'
  end

  def pick_answer_b
    '//label[@for="interactive_verification_questions_attributes_0_response_id_b"]//span'
  end

  def pick_answer_c
    '//label[@for="interactive_verification_questions_attributes_1_response_id_c"]//span'
  end

  def pick_answer_d
    '//label[@for="interactive_verification_questions_attributes_1_response_id_d"]//span'
  end

  def submit_btn
    '//input[@name="commit"]'
  end

  def continue_application_btn
    '//a[text()="Continue Application"]'
  end

  def upload_identity_btn
    '//span[@id="upload_identity"]'
  end

  def documents_faq_btn
    '//a[@id="document-faq"]'
  end
end