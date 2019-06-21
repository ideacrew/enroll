module BenefitSponsors
  module Inboxes
    class Inbox
      include Mongoid::Document

      field :access_key, type: String

      # Enable polymorphic associations
      embedded_in :recipient, polymorphic: true

      def post_message(new_message)
      end
    end
  end
end
