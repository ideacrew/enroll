module MailDelivery
  class SoaMailer
    include Acapi::Notifiers

    def deliver!(email)
      recipient = mail.to.first
      subject = mail.subject
      body = mail.body
      send_email_html(recipient, subject, body)
    end
  end
end
