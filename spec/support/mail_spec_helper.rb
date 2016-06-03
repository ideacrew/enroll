module MailSpecHelper
  shared_context "MailSpecHelper" do
    def refresh_mailbox
      ActionMailer::Base.delivery_method = :test
      ActionMailer::Base.perform_deliveries = true
      ActionMailer::Base.deliveries = []
    end

    def user_mailer_invitation_subject
      "Invitation from your Employer to Sign up for Health Insurance at #{Settings.site.short_name} "
    end

    def user_mailer_invitation_body(person_name)
      [person_name, "Your employer has created a Health Benefits Program through #{Settings.site.short_name}.",
       'Please visit',
       "to learn more about your benefits and sign up for insurance during open enrollment."]
    end
  end
end
