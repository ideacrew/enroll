module BenefitSponsors
  class ApplicationController < ActionController::Base
    protect_from_forgery with: :exception
    include Pundit

    before_filter :require_login, unless: :authentication_not_required?
    rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

    def self.current_site
      if BenefitSponsors::Site.by_site_key(:dc).present?
        BenefitSponsors::Site.by_site_key(:dc).first
      elsif BenefitSponsors::Site.by_site_key(:cca).present?
        BenefitSponsors::Site.by_site_key(:cca).first
      end
    end

    protected

    def authentication_not_required?
      devise_controller? ||
      (controller_name == "registrations") ||
      (controller_name == "office_locations") ||
      (controller_name == "invitations") ||
      (controller_name == "saml")
    end

    def require_login
      unless current_user
        unless request.format.js?
          session[:portal] = url_for(params)
        end
        redirect_to main_app.new_user_registration_path
      end
    rescue Exception => e
      message = {}
      message[:message] = "Application Exception - #{e.message}"
      message[:session_person_id] = session[:person_id] if session[:person_id]
      message[:user_id] = current_user.id if current_user
      message[:oim_id] = current_user.oim_id if current_user
      message[:url] = request.original_url
      message[:params] = params if params
      log(message, :severity=>'error')
    end

    def set_flash_by_announcement
      return if current_user.blank?
      if flash.blank? || flash[:warning].blank?
        announcements = if current_user.has_hbx_staff_role?
                          Announcement.get_announcements_by_portal(request.path, @person)
                        else
                          current_user.get_announcements_by_roles_and_portal(request.path)
                        end
        dismiss_announcements = JSON.parse(session[:dismiss_announcements] || "[]") rescue []
        announcements -= dismiss_announcements
        flash.now[:warning] = announcements
      end
    end

    def create_sso_account(user, personish, timeout, account_role = "individual")
      if !user.idp_verified?
        IdpAccountManager.create_account(user.email, user.oim_id, stashed_user_password, personish, account_role, timeout)
        session[:person_id] = personish.id
        session.delete("stashed_password")
        user.switch_to_idp!
      end
      #TODO TREY KEVIN JIM CSR HAS NO SSO_ACCOUNT
      session[:person_id] = personish.id if current_user.try(:person).try(:agent?)
      yield
    end

    def stashed_user_password
      session["stashed_password"]
    end

    private

    def user_not_authorized(exception)
      policy_name = exception.policy.class.to_s.underscore

      flash[:error] = "Access not allowed for #{exception.query}, (Pundit policy)"
      respond_to do |format|
        format.json { render nothing: true, status: :forbidden }
        format.html { redirect_to(request.referrer || main_app.root_path)}
        format.js   { render nothing: true, status: :forbidden }
      end
    end
  end
end
