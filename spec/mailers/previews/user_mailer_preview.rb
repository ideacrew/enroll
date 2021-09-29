# frozen_string_literal: true

# Class for testing emails in browser
class UserMailerPreview < ActionMailer::Preview
  def welcome_email
    UserMailer.welcome(User.first)
  end

  def generic_user_welcome
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
end
