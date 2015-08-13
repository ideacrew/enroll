module API
  module V1
    class Slcsp < Grape::API
      version 'v1'
      format :json

      resource :slcsp do
        get do

        end
      end
    end
  end
end