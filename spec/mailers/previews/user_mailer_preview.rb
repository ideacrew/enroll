# frozen_string_literal: true

# Class for testing emails in browser
# Visit http://localhost:3000/rails/mailers/
# And you'll see an index of emails
class UserMailerPreview < ActionMailer::Preview
  def broker_staff_invitation_email
    person = Person.all.to_a.sample
    person.emails.create!(
      kind: 'work',
      address: "fakeemail50@gmail.com"
    )
    email = person.emails.last
    person_name = person.full_name
    person_id = person.id.to_s
    person.build_broker_role
    user = User.all.to_a.sample
    invitation = Invitation.create!(
      invitation_email: email,
      source_id: user.id,
      invitation_email_type: "broker_role",
      source_kind: "broker_role",
      role: "broker_role"
    )
    UserMailer.broker_staff_invitation_email(email, person_name, invitation, person_id)
  end

  def broker_denied
    person = Person.all.to_a.sample
    person.emails.create!(
      kind: 'work',
      address: "fakeemail50@gmail.com"
    )
    broker_role = person.build_broker_role
    UserMailer.broker_denied_notification(broker_role)
  end

  def welcome_email
    UserMailer.welcome(User.first)
  end

  def broker_pending_missing_training_completed_carrier
    # Needs to satisfy: !broker_role.training && !unchecked_carriers.present?
    person = Person.all.to_a.sample
    broker_role = person.build_broker_role
    unchecked_carriers = {}
    UserMailer.broker_pending_notification(broker_role, unchecked_carriers)
  end

  def broker_application_confirmation
    person = Person.all.to_a.sample
    person.emails.create!(
      kind: 'work',
      address: "fakeemail50@gmail.com"
    )
    UserMailer.broker_application_confirmation(person)
  end

  def generic_consumer
    UserMailer.generic_consumer_welcome(Person.first.first_name, Person.first.hbx_id, "genericemail@exmaple.com")
  end

  def broker_invitation_email
    user = User.all.to_a.detect { |user_record| user_record.person.present? }
    email = user.email
    person_name = user.person.full_name
    invitation = Invitation.create!(
      invitation_email: email,
      source_id: user.id,
      invitation_email_type: "broker_role",
      source_kind: "broker_role",
      role: "broker_role"
    )
    UserMailer.broker_invitation_email(email, person_name, invitation)
  end

  def invitation_email
    user = User.first
    email = user.email
    person_name = user.person.full_name
    invitation = Invitation.create!(
      invitation_email: email,
      source_id: user.id,
      invitation_email_type: "employer_staff_role",
      source_kind: "employer_staff_role",
      role: "employer_staff_role"
    )
    UserMailer.invitation_email(email, person_name, invitation)
  end

  def message_to_broker
    user = User.all.to_a.detect { |user_record| user_record.person.present? }
    # TODO: need to make an actual broker role for this
    #broker = user.person
    broker = BrokerRole.new(person: Person.all.detect { |person| person.emails.present? })
    person = user.person
    UserMailer.message_to_broker(person, broker, params)
  end

  def plan_shopping_completed
    enrollment = HbxEnrollment.all.detect { |hbx| hbx.product.present? }
    user = User.first
    plan_decorator = UnassistedPlanCostDecorator.new(enrollment.product, enrollment)
    UserMailer.plan_shopping_completed(user, enrollment, plan_decorator)
  end

  def new_client_notification

  end

  def broker_pending_completed_training_missing_carrier

  end

  def reset_password_instructions

  end
end
