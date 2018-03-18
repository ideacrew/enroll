module SponsoredBenefits
  module RatingModels
    class MemberRelationship
      include Mongoid::Document
      include Mongoid::Timestamps


      # ACA_SHOP_PERSONAL_RELATINSHIP_KINDS = [
      #                                           :employee, 
      #                                           :spouse, 
      #                                           :domestic_partner, 
      #                                           :child_under_26, 
      #                                           :child_26_and_over
      #                                         ]

      # ACA_INDIVIDUAL_PERSONAL_RELATINSHIP_KINDS = [
      #                                                 :self, 
      #                                                 :spouse, 
      #                                                 :domestic_partner, 
      #                                                 :child
      #                                               ]

      embedded_in :rating_tier, class_name: "SponsoredBenefits::RatingModels::RatingTier"

      # Mapped relationships are evaulated in ordered sequence
      field :ordinal_position,          type: Integer
      field :key,                       type: Symbol
      field :title,                     type: String
      field :member_relationship_kinds, type: Array, default: []


      embeds_one  :sponsor_credit, 
                  class_name: "SponsoredBenefits::RatingModels::SponsorCredit"

      validates_presence_of :ordinal_position, :key, :member_relationship_kinds



      def reduce_relationships

        # MA relationships
        # :employee,  # => employee
        # :survivor,  # => survivor
        # :spouse,    # => spouse, domestic partner, 
        # :dependent, # => child + age < 26, child + is_disabled? 


        # Congress relationships
        # :employee,  # => employee, survivor
        # :survivor,  # => survivor
        # :dependent, # => spouse, domestic partner, child, child + age < 26, child + is_disabled? 

      end


      def relationship_to_tier_map

        # MA mapping
        # employee_only:                        [:employee == 1, :spouse == 0, :dependent == 0, :survivor == 0],
        # employee_and_spouse_only:             [:employee == 1, :spouse == 1, :dependent == 0, :survivor == 0],
        # employee_and_one_or_more_dependents:  [:employee == 1, :spouse == 0, :dependent > 0,  :survivor == 0],
        # family:                               [:employee == 1, :spouse == 1, :dependent > 0,  :survivor == 0],

        # Congress mapping
        # employee_only:                        [:employee == 1, :spouse == 0, :dependent == 0, :survivor == 0],
        # employee_and_one_dependent:           [:employee == 1, :spouse == 0, :dependent == 1, :survivor == 0],
        # employee_and_two_or_more_dependents:  [:employee == 1, :spouse == 0, :dependent > 1,  :survivor == 0],

      end


    end
  end
end
