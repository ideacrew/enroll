class Api::V1::ApiController < Api::V1::ApiBaseController

  before_action :authenticate_user!

  def ping
    response = {
      ping:    'pong',
      whoami:  'Enroll API',
      version: 'v1',
    }
    render json: response
  end
end
