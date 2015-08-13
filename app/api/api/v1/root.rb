module API
  module V1
    class Root < Grape::API
      mount API::V1::Slcsp
    end
  end
end