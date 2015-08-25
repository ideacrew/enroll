class UserMailer < ApplicationMailer

 if Rails.env.production?
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

  def message_to_broker(person, broker, params)
    mail({to: broker.email_address, subject: params[:subject], from: person.user.email}) do |format|
      format.html { render "message_to_broker", :locals => { :person => person, :broker => broker, :message_body => params[:body] }}
    end
  end

  def message_to_assister(person, assister)
    mail({to: person.user.email_address, subject: "Plan Selection Help", from: person.user.email}) do |format|
      format.html { render "message_to_assister", :locals => { :person => person, :assister => assister}}
    end
  end
 
  def message_to_enrolled_by_agent(person, assister)
    mail({to: person.emails.first.address, subject: "Your Enrollment Progress", from: person.user.email}) do |format|
      format.html { render "message_to_enrollee", :locals => { :person => person, :assister => assister}}
    end
  end

end 
