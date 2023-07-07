module Eligible
  module Concerns
    module Eligibility
      extend ActiveSupport::Concern

      included do
        field :title, type: String
        field :description, type: String

        embeds_many :state_histories,
                    class_name: '::Eligible::StateHistory',
                    cascade_callbacks: true,
                    as: :status_trackable
      end

      class_methods {}
    end
  end
end
