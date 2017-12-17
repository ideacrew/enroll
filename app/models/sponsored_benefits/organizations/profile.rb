module SponsoredBenefits
  module Organizations
    class Profile
      include Mongoid::Document
      include Mongoid::Timestamps

      embedded_in :organization

      delegate :hbx_id, to: :organization, allow_nil: true
      delegate :legal_name, :legal_name=, to: :organization, allow_nil: true
      delegate :dba, :dba=, to: :organization, allow_nil: true
      delegate :fein, :fein=, to: :organization, allow_nil: true
      delegate :is_active, :is_active=, to: :organization, allow_nil: false
      delegate :updated_by, :updated_by=, to: :organization, allow_nil: false

      embeds_one  :inbox, as: :recipient, cascade_callbacks: true
      embeds_many :documents, as: :documentable

    end
  end
end
