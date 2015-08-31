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

  def new_client_notification(insured, agent, role)
    first_name = insured.first_name
    name = first_name + ' ' + insured.last_name
    subject = "New Client Notification -[#{name}]"
    agent_email = agent.user.email
    mail({to: agent_email, subject: subject, from: 'no-reply@individual.dchealthlink.com'}) do |format|
      format.html { render "new_client_notification", :locals => { first_name: first_name, :role => role, name: name}}
    end
  end

  def generic_consumer_welcome(first_name, hbx_id, email)
    message = mail({to: email, subject: 'DC HealthLink', from: 'no-reply@individual.dchealthlink.com'}) do |format|
      format.html {render "generic_consumer", locals: {first_name: first_name, hbx_id: hbx_id}}
    end
  end
end
