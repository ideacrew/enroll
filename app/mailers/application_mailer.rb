class ApplicationMailer < ActionMailer::Base
  default from: "no-reply@shop.dchealthlink.com"

  if Rails.env.production?
    self.delivery_method = :soa_mailer
  end

  def notice_email(notice)
    mail({ to: notice.to, subject: notice.subject}) do |format|
      format.html { notice.html }
    end
  end
end
