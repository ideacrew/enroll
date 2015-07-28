class UserMailer < ApplicationMailer

  Rails.env.production? do
   self.delivery_method = :soa_mailer
 end

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
    mail({to: email, subject: "DCHealthLink Invitation "}) do |format|
      format.html { render "invitation_email", :locals => { :person_name => person_name, :invitation => invitation }}
    end
  end

end 
