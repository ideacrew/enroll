class InvitationsController < ApplicationController
  before_filter :require_login_and_allow_new_account
  
  def claim

  end

  def require_logon_and_allow_new_account
    session[:portal] = url_for(params)
    redirect_to new_user_session_url(:invitation_id => params[:id])
  end
end
