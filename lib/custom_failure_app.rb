class CustomFailureApp < Devise::FailureApp
  def redirect
    message = warden.message || warden_options[:message]
    if (message == :timeout)
      redirect_to("#{SamlInformation.iam_login_url}") and return
    else
      super
    end
  end
end
