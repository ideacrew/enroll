# frozen_string_literal: true

class UserMailer < ApplicationMailer
  ### helper makes the view helper methods available in the Mailer templates. It does NOT make the methods available in the Mailer itself
  ### Thus we have to use Include in addition to helper
  helper Config::AcaHelper
  helper Config::SiteHelper
  helper Config::ContactCenterHelper
  helper ::L10nHelper
  include Config::AcaHelper
  include Config::SiteHelper
  include Config::ContactCenterHelper
  include ::L10nHelper
  layout EnrollRegistry[:custom_email_templates].settings(:email_template).item if EnrollRegistry.feature_enabled?(:custom_email_templates)



  def welcome(user)
    mail({to: user.email, subject: "Thank you for registering."}, &:text) if user.email.present?
  end

  def plan_shopping_completed(user, hbx_enrollment, plan_decorator)
    if user.email.present?
      mail({to: user.email, subject: "Your #{site_short_name} Enrollment Confirmation"}) do |format|
        format.html { render "plan_shopping_completed", :locals => { :user => user, :enrollment => hbx_enrollment, :plan => plan_decorator } }
      end
    end
  end

  def invitation_email(email, person_name, invitation)
    if email.present?
      mail({to: email, subject: "Invitation from your Employer to Sign up for Health Insurance at #{site_short_name} "}) do |format|
        format.html { render "invitation_email", :locals => { :person_name => person_name, :invitation => invitation }}
      end
    end
  end

  #Email will sent to census employees as soon as they are added to the roster
  # TODO: Refactor this as feature with ResourceRegistry
  def send_employee_open_enrollment_invitation(email, census_employee, invitation)
    # TODO: - Move logic to model
    benefit_applications = census_employee.benefit_sponsorship.benefit_applications.published.select{|ba| ba.effective_period.cover?(census_employee.earliest_effective_date)}
    # rubocop:disable Style/GuardClause
    if email.present? && benefit_applications.any?(&:is_submitted?)
      if census_employee.hired_on > TimeKeeper.date_of_record
        mail({to: email, subject: "You Have Been Invited to Sign Up for Employer-Sponsored Coverage through the #{site_short_name}"}) do |format|
          if EnrollRegistry[:enroll_app].setting(:site_key).item
            format.html { render "dc_invite_future_employee_for_open_enrollment", :locals => { :census_employee => census_employee, :invitation => invitation }}
          else
            format.html { render "invite_future_employee_for_open_enrollment", :locals => { :census_employee => census_employee, :invitation => invitation }}
          end
        end
      else
        mail({to: email, subject: "Enroll Now: Your Plan Open Enrollment Period has Begun"}) do |format|
          if EnrollRegistry[:enroll_app].setting(:site_key).item
            format.html { render "dc_invite_initial_employee_for_open_enrollment", :locals => { :census_employee => census_employee, :invitation => invitation }}
          else
            format.html { render "invite_initial_employee_for_open_enrollment", :locals => { :census_employee => census_employee, :invitation => invitation }}
          end
        end
      end
    # rubocop:enable Style/GuardClause
    end
  end

  #Email will be sent to census employees when they reach the DOH.
  def send_future_employee_open_enrollment_invitation(email, census_employee, invitation)
    benefit_applications = census_employee.benefit_sponsorship.benefit_applications.published.select{|ba| ba.effective_period.cover?(census_employee.earliest_effective_date)}
    # rubocop:disable Style/GuardClause
    if email.present? && benefit_applications.any?(&:is_submitted?)
      mail({to: email, subject: "Enroll Now: Your Plan Open Enrollment Period has Begun"}) do |format|
        format.html { render "invite_initial_employee_for_open_enrollment", :locals => { :census_employee => census_employee, :invitation => invitation }}
      end
    end
    # rubocop:enable Style/GuardClause
  end

  def renewal_invitation_email(email, census_employee, invitation)
    mail({to: email, subject: "Enroll Now: Your Plan Open Enrollment Period has Begun"}) do |format|
      format.html { render "renewal_invitation_email", :locals => { :census_employee => census_employee, :invitation => invitation }}
    end
  end

  # TODO: Figure out how to refactor this with ResourceRegistry
  def initial_employee_invitation_email(email, census_employee, invitation)
    mail({to: email, subject: "Enroll Now: Your Plan Open Enrollment Period has Begun"}) do |format|
      if EnrollRegistry[:enroll_app].setting(:site_key).item == :dc
        format.html { render "dc_initial_employee_invitation_email", :locals => { :census_employee => census_employee, :invitation => invitation }}
      else
        format.html { render "initial_employee_invitation_email", :locals => { :census_employee => census_employee, :invitation => invitation }}
      end
    end
  end

  def agent_invitation_email(email, person_name, invitation, person_id = nil)
    if email.present?
      mail({to: email, subject: "#{site_short_name} Support Invitation"}) do |format|
        format.html { render "agent_invitation_email", :locals => { :person_name => person_name, :invitation => invitation, :person_id => person_id }}
      end
    end
  end

  def broker_invitation_email(email, person_name, invitation)
    if email.present?
      mail({to: email, subject: "Invitation to create your Broker account on #{site_short_name}"}) do |format|
        format.html { render "broker_invitation_email", :locals => { :person_name => person_name, :invitation => invitation }}
      end
    end
  end

  def broker_staff_invitation_email(email, person_name, invitation, person_id)
    return if email.blank?

    mail({to: email, subject: "Set up your #{site_short_name} account"}) do |format|
      format.html { render "broker_staff_invitation_email", :locals => { :person_name => person_name, :invitation => invitation, :person_id => person_id }}
    end
  end

  # Only when "broker_role_consumer_enhancement" (cr-95) is enabled, the below email will be sent to the broker.
  # site_broker_linked_invitation_email_login_url only applies when "broker_role_consumer_enhancement" is enabled.
  def broker_linked_invitation_email(email, person_name)
    return if email.blank?

    mail({to: email, subject: l10n("user_mailer.broker_linked_notification_email.subject")}) do |format|
      format.html { render "broker_linked_notification_email", :locals => { :person_name => person_name, :login_url => site_broker_linked_invitation_email_login_url }}
    end
  end

  # Only when "broker_role_consumer_enhancement" (cr-95) is enabled, the below email will be sent to the broker staff.
  # site_broker_linked_invitation_email_login_url only applies when "broker_role_consumer_enhancement" is enabled.
  def broker_staff_linked_invitation_email(email, person_name)
    return if email.blank?

    mail({to: email, subject: l10n("user_mailer.broker_staff_linked_notification_email.subject")}) do |format|
      format.html { render "broker_staff_linked_notification_email", :locals => { :person_name => person_name, :login_url => site_broker_linked_invitation_email_login_url }}
    end
  end

  def message_to_broker(person, broker, params)
    if broker.email_address.present?
      mail({to: broker.email_address, subject: params[:subject], from: person.user.email}) do |format|
        format.html { render "message_to_broker", :locals => { :person => person, :broker => broker, :message_body => params[:body] }}
      end
    end
  end

  def send_employee_ineligibility_notice(email, first_name)
    if email.present?
      # rubocop:disable Lint/UselessAssignment
      message = mail({to: email, subject: "#{EnrollRegistry[:enroll_app].setting(:short_name).item} - Assistance Enrolling in Employer-sponsored Insurance", from: mail_address.to_s}) do |format|
      # rubocop:enable Lint/UselessAssignment
        format.html {render "employee_ineligibility_notice", locals: {first_name: first_name}}
      end
    end
  end

  def new_client_notification(agent_email, name, role, insured_email, hbx_id)
    if agent_email.present?
      subject = l10n("user_mailer.new_client_notification_subject.full_text", name: name, insured_email: insured_email, site_short_name: site_short_name)
      mail({to: agent_email, subject: subject, from: "no-reply@individual.#{site_domain_name}"}) do |format|
        format.html { render "new_client_notification", :locals => { :role => role, name: name, hbx_id: hbx_id, email: insured_email }}
      end
    end
  end

  def generic_consumer_welcome(first_name, hbx_id, email)
    if email.present?
      mail({to: email, subject: site_short_name, from: "no-reply@individual.#{site_domain_name}"}) do |format|
        format.html { render "generic_consumer", locals: {first_name: first_name, hbx_id: hbx_id} }
      end
    end
  end

  def generic_notice_alert(first_name, notice_subject, email, files_to_attach = {})
    files_to_attach.each do |file_name, file_path|
      attachments[file_name.to_s] = File.read(file_path)
    end
    message =  mail({to: email, subject: "You have a new message from #{site_short_name}", from: "no-reply@individual.#{site_domain_name}"}) do |format|
      format.html {render "generic_notice_alert", locals: {first_name: first_name, notice_subject: notice_subject}}
    end
  end

  def tax_form_notice_alert(first_name, email)
    mail({to: email, subject: "You have a new tax document from #{site_short_name}", from: "no-reply@individual.#{site_domain_name}"}) do |format|
      format.html {render "tax_form_notice_alert", locals: {first_name: first_name}}
    end
  end

  def generic_notice_alert_to_ba_and_ga(first_name, email, employer_name)
    return if email.blank?

    mail({to: email, subject: "You have a new message from #{site_short_name}", from: "no-reply@individual.#{site_domain_name}"}) do |format|
      format.html {render "generic_notice_alert_to_broker_and_ga", locals: {first_name: first_name, employer_name: employer_name}}
    end
  end

  def generic_notice_alert_to_ba(first_name, email, employer_name)
    if email.present?
      # rubocop:disable Lint/UselessAssignment
      message = mail({to: email, subject: "You have a new message from #{site_short_name}", from: mail_address.to_s}) do |format|
      # rubocop:enable Lint/UselessAssignment
        format.html {render "generic_notice_alert_to_broker", locals: {first_name: first_name, employer_name: employer_name}}
      end
    end
  end

  def employer_invoice_generation_notification(employer,subject)
    mail({to: employer.email, subject: subject, from: "no-reply@individual.#{site_domain_name}"}) do |format|
      format.html {render "employer_invoice_generation", locals: {first_name: employer.person.first_name}}
    end
  end

  def broker_registration_guide(user)
    attachments['Broker Registration Guide.pdf'] = File.read('public/new_broker_registration.pdf')
    mail({to: user[:email], subject: "Broker Registration Guide"}) do |format|
      format.html { render "broker_registration_guide", :locals => { :first_name => user[:first_name]}}
    end
  end

  def broker_denied_notification(broker_role)
    if broker_role.email_address.present?
      mail({to: broker_role.email_address, subject: "Broker application denied"}) do |format|
        format.html { render "broker_denied", :locals => { :applicant_name => broker_role.person.full_name }}
      end
    end
  end

  def broker_application_confirmation(person)
    if person.emails.find_by(kind: 'work').address.present?
      mail({to: person.emails.find_by(kind: 'work').try(:address), subject: "Thank you for submitting your broker application to #{site_short_name}"}) do |format|
        format.html { render "broker_application_confirmation", :locals => { :person => person }}
      end
    end
  end

  def broker_pending_notification(broker_role,unchecked_carriers)
    subject_sufix = unchecked_carriers.present? ? ", missing carrier appointments" : ", has all carrier appointments"
    subject_translation_key = broker_role.training || broker_role.training == true ? "user_mailer.broker_pending_completed_training.subject" : "user_mailer.broker_pending_training.subject"
    subject = l10n(subject_translation_key, site_short_name: site_short_name)
    mail({to: broker_role.email_address, subject: subject}) do |format|
      if broker_role.training && unchecked_carriers.present?
        format.html { render "broker_pending_completed_training_missing_carrier", :locals => { :applicant_name => broker_role.person.full_name,:unchecked_carriers => unchecked_carriers}}
      elsif !broker_role.training && !unchecked_carriers.present?
        format.html { render "broker_pending_missing_training_completed_carrier", :locals => { :applicant_name => broker_role.person.full_name, :unchecked_carriers => unchecked_carriers}}
      elsif !broker_role.training && unchecked_carriers.present?
        format.html { render "broker_pending_missing_training_and_carrier", :locals => { :applicant_name => broker_role.person.full_name, :unchecked_carriers => unchecked_carriers}}
      end
    end
  end

  def account_transfer_success_notification(person, email_address, hbx_id)
    mail({to: email_address, subject: "Action needed to get covered on #{site_short_name}"}) do |format|
      format.html { render "account_transfer_success_notification", :locals => { :person_name => person.full_name, hbx_id: hbx_id }}
    end
  end

  def identity_verification_denial(email_address, first_name, hbx_id)
    mail({to: email_address, subject: "Action needed to complete your #{site_short_name} application"}) do |format|
      format.html { render "identity_verification_denial", :locals => { :first_name => first_name, :hbx_id => hbx_id }}
    end
  end

  def identity_verification_acceptance(email_address, first_name, hbx_id)
    mail({to: email_address, subject: "Time to complete your #{site_short_name} application"}) do |format|
      format.html { render "identity_verification_acceptance", :locals => { :first_name => first_name, :hbx_id => hbx_id }}
    end
  end
end
