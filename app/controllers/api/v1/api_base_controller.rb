class Api::V1::ApiBaseController < ActionController::Base
  respond_to :json

  include Pundit

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  def user_not_authorized(exception)
    render file: 'public/403.html', status: 403
    # render nothing: true, status: :forbidden
  end
end
