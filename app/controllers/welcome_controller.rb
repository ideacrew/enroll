class WelcomeController < ApplicationController
  layout 'bootstrap_4'
  skip_before_action :require_login
  before_action :set_same_site_cookie_attribute, only: [:index]

  def show_hints
    current_user.hints = !current_user.hints
    current_user.save
    render json: nil, status: :ok
  end

  def index
  end

  def qna_bot
    render :layout => false
  end


  def form_template
    # created for generic form template access at '/templates/form-template'
  end

  private

  def set_same_site_cookie_attribute
    response.headers['Set-Cookie'] = 'SameSite=Strict'
  end

end
