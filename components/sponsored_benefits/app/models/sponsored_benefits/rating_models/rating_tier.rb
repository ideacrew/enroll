module SponsoredBenefits
  module RatingModels
    class RatingTier
      include Mongoid::Document
      include Mongoid::Timestamps

      CREDIT_STRUCTURE_KINDS = [ 
                                  :percent_with_cap,                  # Congress
                                  :reference_plan_percent,            # DC SHOP list bill
                                  :group_composite_percent,           # MA SHOP
                                  :fixed_dollar_only,                 # DC Individual financial assistance
                                  :reference_plan_percent_with_cap,  
                                  :percent_only, 
                                ]

      # Mapped relationships are evaulated in ordered sequence
      field :ordinal_position,                  type: Integer
      field :key,                               type: Symbol
      field :title,                             type: String
      field :description,                       type: String, default: ""
      field :is_offered,                        type: Boolean

      # Sponsor must offer contributions toward to this rating tier
      field :is_required,                       type: Boolean

      field :sponsor_credit_structure_kind,     type: Symbol

      embeds_one  :credit_structure, as: :sponsor_contribution,
                  class_name: "SponsoredBenefits::RatingModels::CreditStructure"

      embeds_many :member_relationships,
                  class_name: "SponsoredBenefits::RatingModels::MemberRelationship"

      validates_presence_of :ordinal_position, :is_offered, :is_required, :sponsor_contribution,
                            :member_relationships


      validates :sponsor_credit_structure_kind,
        inclusion:  { in: CREDIT_STRUCTURE_KINDS, message: "%{value} is not a valid credit structure kind" },
        allow_nil:  false


      alias_method :is_offered?, :is_offered
      alias_method :is_required?, :is_required


      def sponsor_credit_structure_kind=(new_sponsor_credit_structure_kind)
        # Use same strategy as BenefitMarket#kind to associate the appropriate subclass here
      end


    end
  end
end
