module BenefitSponsors
  module Organizations
    class OrganizationForms::InboxForm
      include Virtus.model
      include ActiveModel::Validations

      attribute :access_key, String
      attribute :messages, Array[OrganizationForms::MessageForm]
      attribute :unread_messages_count, Integer

      def persisted?
        false
      end

    end
  end
end
