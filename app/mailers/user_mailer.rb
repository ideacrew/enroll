class UserMailer < ApplicationMailer
  self.delivery_method = :soa_mailer
  def welcome(user)
    mail({to: user.email, subject: "Thank you for registering."}) do |format|
      format.text
    end
  end

  def plan_shopping_completed(user, hbx_enrollment, plan_decorator)
    mail({to: user.email, subject: "DCHealthLink Confirmation"}) do |format|
      format.html { render "plan_shopping_completed", :locals => { :user => user, :enrollment => hbx_enrollment, :plan => plan_decorator } }
    end
  end

  def invitation_email(email, person_name, invitation)
    mail({to: user.email, subject: "DCHealthLink Invitation "}) do |format|
      format.html { render "broker_invitation", :locals => { :person_name => person_name, :invitation => invitation }}
    end
  end

  def self.invite_employee!(census_employee)

  end
end 
