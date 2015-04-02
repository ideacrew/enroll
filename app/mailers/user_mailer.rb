class UserMailer < ApplicationMailer
  self.delivery_method = :soa_mailer
  def welcome(user)
    mail({to: user.email, subject: "Thank you for registering."}) do |format|
      format.text
    end
  end
end 
