module MailDelivery
  class SoaMailer
    include Acapi::Notifiers

    def initialize(*vals)
      # A slug because mail insists on invoking it
    end

    def deliver!(mail)
      recipient = mail.to.first
      subject = mail.subject
      body = mail.body.raw_source
      send_email_html(recipient, subject, body)
    end
  end
end
