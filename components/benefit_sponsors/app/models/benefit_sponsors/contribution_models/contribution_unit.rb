module BenefitSponsors
  module ContributionModels
    class ContributionUnit
      include Mongoid::Document
      include Mongoid::Timestamps

      embedded_in :contribution_model, inverse_of: :contribution_units

      field :name, type: String
      field :required, type: Boolean, default: false
      field :order, type: Integer

      validates_presence_of :name, :allow_blank => false
      validates_presence_of :order
    end
  end
end
