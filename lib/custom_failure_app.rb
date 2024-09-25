class CustomFailureApp < Devise::FailureApp
  include Config::SiteConcern

  def redirect
    message = warden.message || warden_options[:message]
    if (message == :timeout)
      redirect_to("#{site_redirect_on_timeout_route}") and return
    else
      # this 'else' condition is basically the same as the original Devise::FailureApp#redirect method
      # with the exception of the flash[:timedout] && flash[:alert] condition
      # which will return a flash message solely consisting of the word "true" if flash[:timedout] is present
      store_location!
      if is_flashing_format?
        flash[:alert] = i18n_message unless flash[:timedout] && flash[:alert]
      end
      redirect_to redirect_url
    end
  end
end
