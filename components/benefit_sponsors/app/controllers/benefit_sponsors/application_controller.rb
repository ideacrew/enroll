module BenefitSponsors
  class ApplicationController < ActionController::Base
    protect_from_forgery with: :exception
    include Pundit

    helper BenefitSponsors::Engine.helpers

    rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

    def self.current_site
      if BenefitSponsors::Site.by_site_key(:dc).present?
        BenefitSponsors::Site.by_site_key(:dc).first
      elsif BenefitSponsors::Site.by_site_key(:cca).present?
        BenefitSponsors::Site.by_site_key(:cca).first
      end
    end

    protected

    def set_current_person(required: true)
      if current_user.try(:person).try(:agent?) && session[:person_id].present?
        @person = Person.find(session[:person_id])
      else
        @person = current_user.person
      end
      redirect_to logout_saml_index_path if required && !set_current_person_succeeded?
    end

    def set_current_person_succeeded?
      return true if @person
      message = {}
      message[:message] = 'Application Exception - person required'
      message[:session_person_id] = session[:person_id]
      message[:user_id] = current_user.id
      message[:oim_id] = current_user.oim_id
      message[:url] = request.original_url
      log(message, :severity=>'error')
      return false
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
      session[:person_id] = personish.id if user.person && user.person.agent?
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
