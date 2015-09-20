class WelcomeController < ApplicationController
  skip_before_filter :require_login

  def index

  end

  def form_template
  	# created for generic form template access at '/templates/form-template'
  end
end
