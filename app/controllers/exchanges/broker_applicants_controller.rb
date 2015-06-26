class Exchanges::BrokerApplicantsController < ApplicationController
  before_action :check_hbx_staff_role

  def index
    @broker_roles = BrokerRole.all

    respond_to do |format|
      format.html
      format.js
    end
  end

  def edit
    @broker_role = BrokerRole.find(BSON::ObjectId.from_string(params[:id]))
  end

  def update
    broker_role = BrokerRole.find(BSON::ObjectId.from_string(params[:id]))
    broker_role.comments = params[:broker_role][:comments]
    broker_role.save!

    if params[:decertify].present?
      broker_role.decertify!
      flash[:notice] = "Broker applicant decertified successfully."
    else
      broker_role.approve!
      Invitation.invite_broker!(broker_role)
      flash[:notice] = "Broker applicant certified successfully."
    end
    redirect_to "/exchanges/hbx_profiles"
  end

  # def certify_broker
  #   broker_role = BrokerRole.find(BSON::ObjectId.from_string(params[:id]))
  #   password = SecureRandom.hex(5)
  #   user = broker_role.person.user
  #   if user.present?
  #     user.set_random_password(password)
  #   else
  #     person = broker_role.person
  #     user = User.new(:email => person.emails.first.address, :password => password, :password_confirmation => password)
  #     user.roles << "broker"
  #     user.save!
  #     person.user = user
  #     person.save!
  #   end
  #   broker_role.approve!
  #   Invitation.invite_broker!(broker_role)
  #   flash[:notice] = "Broker applicant certified successfully."
  #   redirect_to "/exchanges/hbx_profiles"
  # end
  
  # def decertify_broker
  #   broker_role = BrokerRole.find(BSON::ObjectId.from_string(params[:id]))
  #   broker_role.decertify!
  #   flash[:notice] = "Broker applicant decertified successfully."
  #   redirect_to "/exchanges/hbx_profiles"
  # end

  private

  def check_hbx_staff_role
    unless current_user.has_hbx_staff_role?
      redirect_to root_path, :flash => { :error => "You must be an HBX staff member" }
    end
  end
end