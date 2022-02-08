class ApplicationMailer < ActionMailer::Base

  default from: EnrollRegistry[:enroll_app].setting(:mail_address).item

  if Rails.env.production?
    self.delivery_method = :soa_mailer
  end

  def notice_email(notice)
    mail({ to: notice.to, subject: notice.subject}) do |format|
      format.html { notice.html }
    end
  end
end
