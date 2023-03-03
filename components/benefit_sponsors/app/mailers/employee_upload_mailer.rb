# frozen_string_literal: true

# Employee upload mailer
class EmployeeUploadMailer < ApplicationMailer
  default from: EnrollRegistry[:enroll_app].setting(:mail_address).item

  def success_email(recipient, records_count)
    @records_count = records_count
    mail({to: recipient, subject: "Employees are created."})
  end

  def failure_email(recipient)
    mail({to: recipient, subject: "Employees are not created."})
  end

  def error_email(recipient, error_message)
    @error_message = error_message
    mail({to: recipient, subject: "Something went wrong."})
  end
end
