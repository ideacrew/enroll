class CustomFailureApp < Devise::FailureApp
  def redirect
    message = warden.message || warden_options[:message]
    if (message == :timeout)
      redirect_to('https://www.dchealthlink.com/') and return
    else
      super
    end
  end
end
