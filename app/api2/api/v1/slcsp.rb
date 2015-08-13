module API
  module V1
    class Slcsp < Grape::API
      version 'v1'
      format :xml

      resource :slcsp do
        get do
          "<hello></hello>"
        end
      end
    end
  end
end