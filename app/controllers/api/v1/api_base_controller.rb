class Api::V1::ApiBaseController < ActionController::Base
  respond_to :json

  include Pundit

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized
  rescue_from Mongoid::Errors::DocumentNotFound, with: :record_find_failure

  def user_not_authorized(exception)
    render file: 'public/403.html', status: 403
  end

  def record_find_failure(exception)
    render file: 'public/404.html', status: 404
  end
end
