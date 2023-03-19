# frozen_string_literal: true

# Employee upload mailer
class EmployeeUploadMailer < ApplicationMailer
  include L10nHelper
  default from: EnrollRegistry[:enroll_app].setting(:mail_address).item

  def success_email(recipient, records_count)
    message = records_count.to_s + l10n("employers.employer_profiles.mailer.success")
    mail({to: recipient, subject: "Employees are created."}) do |format|
      format.html { render "success_email", locals: {message: message}}
    end
  end

  def failure_email(recipient)
    message = l10n("employers.employer_profiles.mailer.failure")
    mail({to: recipient, subject: "Employees are not created."}) do |format|
      format.html { render "success_email", locals: {message: message}}
    end
  end

  def error_email(recipient, error_message)
    message = l10n("employers.employer_profiles.mailer.error")
    mail({to: recipient, subject: "Something went wrong."}) do |format|
      format.html { render "success_email", locals: {message: message, error_message: error_message}}
    end
  end
end
