class CustomFailureApp < Devise::FailureApp
  include Config::SiteConcern

  def redirect
    message = warden.message || warden_options[:message]
    redirect_to(site_redirect_on_timeout_route.to_s) and return if message == :timeout

    super
  end
end
