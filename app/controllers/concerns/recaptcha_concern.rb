module RecaptchaConcern
  extend ActiveSupport::Concern

  included do
    prepend_before_action :check_captcha, only: [:create]

    private

    def check_captcha
      unless verify_recaptcha
        current_controller = self.class.to_s
        case current_controller
        when 'Users::RegistrationsController'
          self.resource = resource_class.new sign_up_params
          respond_with_navigational(resource) { render :new }
        when 'Users::SessionsController'
          if User.login_captcha_required?(params[:user][:login])
            self.resource = resource_class.new
            respond_with_navigational(resource) { render :new }
          end
        end
      end
    end

  end
end
