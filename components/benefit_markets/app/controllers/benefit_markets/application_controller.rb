module BenefitMarkets
  class ApplicationController < ActionController::Base
    protect_from_forgery with: :exception

    rescue_from ActionController::InvalidAuthenticityToken, :with => :bad_token_due_to_session_expired

    private

    def bad_token_due_to_session_expired
      flash[:warning] = "Session expired."
      respond_to do |format|
        format.html { redirect_to main_app.root_path}
        format.js   { render text: "window.location.assign('#{main_app.root_path}');"}
      end
    end
  end
end
