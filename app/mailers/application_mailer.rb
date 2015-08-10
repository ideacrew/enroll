class ApplicationMailer < ActionMailer::Base
  default from: "no-reply@shop.dchealthlink.com"

  if Rails.env.production?
    self.delivery_method = :soa_mailer
  end
end
