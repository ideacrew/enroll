class Api::V1::TestController < ApiController

  def index
    render json: "You hit me"
  end
end