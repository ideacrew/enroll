class CustomFailureApp < Devise::FailureApp
  def redirect
    store_location!
    message = warden.message || warden_options[:message]
    if (message == :timeout) && (params[:controller].include? "employer")
      redirect_to "http://www.google.com/"
    else
      super
    end
  end
end
