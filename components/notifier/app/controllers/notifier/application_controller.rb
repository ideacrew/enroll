module Notifier
  class ApplicationController < ActionController::Base
    include Pundit
    layout "notifier/single_column"

    rescue_from ActionController::InvalidAuthenticityToken, :with => :bad_token_due_to_session_expired

    private

    def bad_token_due_to_session_expired
      flash[:warning] = "Session expired."
      respond_to do |format|
        format.html { redirect_to main_app.root_path }
        format.js   { render text: "window.location.assign('#{main_app.root_path}');" }
        format.json { redirect_to main_app.root_path }
      end
    end
  end
end
