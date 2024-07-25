# frozen_string_literal: true

#insured/plan_shoppings/5ff897c796a4a17b7bf8930b/receipt
class IvlEnrollmentSubmitted

  def self.how_to_pay_btn
    'span.btn-default' unless EnrollRegistry[:bs4_consumer_flow].enabled?
  end

  def self.enrollment_submitted_text
    'Enrollment Submitted'
  end

  def self.pay_now_btn
    '.interaction-click-control-pay-now' unless EnrollRegistry[:bs4_consumer_flow].enabled?
  end

  def self.go_back_btn
    '.interaction-click-control-go-back' unless EnrollRegistry[:bs4_consumer_flow].enabled?
  end

  def self.print_btn
    '#btnPrint'
  end

  def self.go_to_my_acct_btn
    '#btn-continue'
  end

  def self.help_me_sign_up
    '.help-me-sign-up'
  end
end
