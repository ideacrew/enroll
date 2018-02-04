class ApiController < ActionController::Base
  before_filter :verify_jwt_token
  
  # This method can be used as a before filter to protect
  # any actions by ensuring the request is transmitting a
  # valid JWT.
  def verify_jwt_token
    if request.headers['Authorization'].nil? || !AuthToken.valid?(request.headers['Authorization'].split(' ').last)
      self.status = 401
      self.response_body = "Invalid or missing token detected."
    elsif AuthToken.valid?(request.headers['Authorization'].split(' ').last)
      @current_user_id = AuthToken.valid?(request.headers['Authorization'].split(' ').last)[0]['user_id']
      @current_user = User.where(id:@current_user_id).first
    end  
  end
    
end