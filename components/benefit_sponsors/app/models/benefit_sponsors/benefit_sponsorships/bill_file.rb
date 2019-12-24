# frozen_string_literal: true

module BenefitSponsors
  module BenefitSponsorships
    class BillFile
      include Mongoid::Document
      include Mongoid::Timestamps

      field :urn, type: String
      field :creation_date, type: Date
      field :name, type: String
    end
  end
end
