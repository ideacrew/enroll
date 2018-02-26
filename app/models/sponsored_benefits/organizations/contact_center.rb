module SponsoredBenefits
  module Organizations
    class ContactCenter
      include Mongoid::Document
      include Mongoid::Timestamps

      field :name,      type: String
      field :alt_name,  type: String

      # Phone number for customer communications
      embeds_many :phones, class_name: "::Phone"

      # Phone number for customer communications
      embeds_many :emails, class_name: "::Email"

      # Addresses for customer communications/notice return address
      embeds_many :addresses, class_name: "::Address"

    end
  end
end
