# frozen_string_literal: true

module MailSpecHelper
  shared_context "MailSpecHelper" do
    def refresh_mailbox
      ActionMailer::Base.delivery_method = :test
      ActionMailer::Base.perform_deliveries = true
      ActionMailer::Base.deliveries = []
    end

    def user_mailer_invitation_subject
      "Invitation from your Employer to Sign up for Health Insurance at #{EnrollRegistry[:enroll_app].setting(:short_name).item} "
    end

    def user_mailer_invitation_body(person_name)
      [person_name, "Your employer has created a Health Benefits Program through #{EnrollRegistry[:enroll_app].setting(:short_name).item}.",
       'Please visit',
       "to learn more about your benefits and sign up for insurance during open enrollment."]
    end

    def user_mailer_renewal_invitation_subject
      "Enroll Now: Your Health Plan Open Enrollment Period has Begun"
    end

    def user_mailer_renewal_invitation_body(census_employee)
      ["Dear #{census_employee.full_name}","Congratulations! #{census_employee.employer_profile.legal_name}, has chosen to renew the offer of health insurance coverage
  to its employees through #{EnrollRegistry[:enroll_app].setting(:short_name).item} and will contribute to the monthly premium to make the cost of coverage more affordable.",
       "You Are Able to Change Your Plan Selection during Open Enrollment"]
    end

    def user_mailer_initial_employee_invitation_body(census_employee)
      short_name = EnrollRegistry[:enroll_app].setting(:short_name).item
      legal_name = census_employee.employer_profile.legal_name.titleize
      oe_date = census_employee.published_benefit_group_assignment.benefit_application.open_enrollment_start_on.to_date.to_formatted_s
      fname = census_employee.full_name
      fname.slice! census_employee.last_name
      # rubocop:disable Layout/LineLength
      ["Dear #{fname.humanize.titleize}","Good News! #{legal_name} has chosen to offer #{short_name} coverage to its employees through The #{short_name} and will contribute to the monthly premium to make the cost of coverage more affordable. Your new open enrollment period begins on #{oe_date}.",
       "To See Plan Options and Enroll:"]
      # rubocop:enable Layout/LineLength
    end
  end
end
