module SponsoredBenefits
  module RatingModels
    class RatingFactor
      include Mongoid::Document
      include Mongoid::Timestamps

      field :rating_model_key,  type: Symbol
      field :key,               type: Symbol
      field :value,             type: Float

      validates_presence_of :rating_model_key, :key, :value

    end
  end
end
