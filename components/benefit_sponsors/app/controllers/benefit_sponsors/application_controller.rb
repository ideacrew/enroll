# frozen_string_literal: true

module BenefitSponsors
  # application controller for the benefit sponsors engine
  class ApplicationController < ActionController::Base
    protect_from_forgery with: :exception
    before_action :set_last_portal_visited
    include Pundit
    include ::L10nHelper
    include ::FileUploadHelper

    helper BenefitSponsors::Engine.helpers

    rescue_from Pundit::NotAuthorizedError, Pundit::NotDefinedError, with: :user_not_authorized
    rescue_from ActionController::InvalidAuthenticityToken, :with => :bad_token_due_to_session_expired
    rescue_from ActionController::UnknownFormat, with: :respond_to_unsupported_format

    # for current_user
    before_action :set_current_user

    def self.current_site
      site_key = EnrollRegistry[:enroll_app].settings(:site_key).item
      BenefitSponsors::Site.by_site_key(site_key).first
    end

    def set_cache_headers
      response.headers["Cache-Control"] = "no-cache, no-store, private"
      response.headers["Pragma"] = "no-cache"
    end

    def set_current_user
      User.current_user = current_user
      User.current_session_values = session
    end

    def clear_current_user
      User.current_user = nil
      User.current_session_values = nil
    end

    append_after_action :clear_current_user

    protected

    def set_current_person(required: true)
      if current_user.try(:person).try(:agent?) && session[:person_id].present?
        @person = Person.find(session[:person_id])
      else
        @person = current_user&.person
      end
      redirect_to logout_saml_index_path if required && !set_current_person_succeeded?
    end

    def set_current_person_succeeded?
      return true if @person
      message = {}
      if current_user
        message[:message] = 'Application Exception - person required'
        message[:session_person_id] = session[:person_id]
        message[:user_id] = current_user.id
        message[:oim_id] = current_user.oim_id
        message[:url] = request.original_url
        log(message, :severity => 'error')
      else
        message[:message] = "User not logged in"
      end
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
        flash.now[:warning] = announcements.map do |announcement|
          { is_announcement: true, announcement: announcement }
        end
      end
    end

    def set_ie_flash_by_announcement
      return unless check_browser_compatibility
      return unless flash.blank? || flash[:warning].blank?

      announcements = Announcement.announcements_for_web
      dismiss_announcements = JSON.parse(session[:dismiss_announcements] || '[]')
      announcements -= dismiss_announcements
      flash.now[:warning] = announcements.map do |announcement|
        { is_announcement: true, announcement: announcement }
      end
    end

    def check_browser_compatibility
      browser.ie? && BenefitSponsorsRegistry[:enroll_app].setting(:support_for_ie_browser).item
    end

    def cur_page_no(alph="a")
      page_string = params.permit(:page)[:page]
      page_string.blank? ? alph : page_string.to_s
    end

    def page_alphabets(source, field)
      # A good optimization would be an aggregate
      # source.collection.aggregate([{ "$group" => { "_id" => { "$substr" => [{ "$toUpper" => "$#{field}"},0,1]}}}, "$sort" =>{"_id"=>1} ]).map do
      #   |object| object["_id"]
      # end
      # but source.collection acts on the entire collection (Model.all) hence cant be used here as source is a Mongoid::Criteria
    source.distinct(field).collect {|word| word.first.upcase}.uniq.sort
    rescue
      ("A".."Z").to_a
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

    def set_last_portal_visited
      if controller_name == "broker_agency_profiles" && action_name == "show"
        return if (current_user.blank? || (current_user.person.present? && !current_user.person.broker_role.present?) ||current_user.last_portal_visited == request.referrer)
        current_user.update_attributes(last_portal_visited: request.path)
      elsif controller_name == "general_agency_profiles" && action_name == "show"
        return if (current_user.blank? || (current_user.person.present? && !current_user.person.general_agency_staff_roles.present?) ||current_user.last_portal_visited == request.referrer)
        current_user.update_attributes(last_portal_visited: request.path)
      end
    end

    private

    def broker_agency_or_general_agency?
      @profile_type == "broker_agency" || @profile_type == "general_agency"
    end

    def user_not_authorized(exception)
      error_type = exception&.class == Pundit::NotDefinedError ? exception&.class : exception&.query

      flash[:error] = "Access not allowed for #{error_type}, (Pundit policy)" unless broker_agency_or_general_agency?
      respond_to do |format|
        format.json { render nothing: true, status: :forbidden }
        format.html { redirect_to(session[:custom_url] || request.referrer || main_app.root_path)}
        format.js   { render nothing: true, status: :forbidden }
      end
    end

    def bad_token_due_to_session_expired
      flash[:warning] = "Session expired."
      respond_to do |format|
        format.html { redirect_to main_app.root_path }
        format.js   { render plain: "window.location.assign('#{root_path}');" }
        format.json { redirect_to main_app.root_path }
      end
    end

    def respond_to_unsupported_format
      message = 'Unsupported format'
      status = :not_acceptable
      content_type = 'text/plain'

      respond_to do |format|
        format.json { render json: { error: message }, status: status }
        format.xml  { render xml: { error: message }.to_xml, status: status }
        format.all { render body: message, status: status, content_type: content_type }
      end
    end
  end
end
