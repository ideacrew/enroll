class ApplicationMailer < ActionMailer::Base
  default from: "noreply@healthconnector.org"

  if Rails.env.production?
    self.delivery_method = :soa_mailer
  end

  def notice_email(notice)
    mail({ to: notice.to, subject: notice.subject}) do |format|
      format.html { notice.html }
    end
  end
end
