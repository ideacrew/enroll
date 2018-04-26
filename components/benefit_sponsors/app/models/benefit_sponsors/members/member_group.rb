# A collection of members, typically a family, who operate as a unit for purposes of benefit coverage
module BenefitSponsors
  class Members::MemberGroup
    include Enumerable

    attr_reader :members

    # Return the date on which the rate schedule is applicable.
    # @return [Date] the rate schedule date
    attr_reader :rate_schedule_date

    # The coverage start date.
    # @return [Date] the coverage start date
    attr_reader :coverage_start_on

    def initialize(group_id = nil)
      @members                    = []

      @group_id                   = group_id
      @coverage_start_on          = nil
      @product                    = nil
      @product_cost_total         = 0.00

      @contribution_model_kind    = nil
      @pricing_model_kind         = nil
      @sponsor_contribution_total = 0.00

      # 123: {
      #   id: 123,
      #   converage_eligibility_on: 
      #   product_price: 120.00,
      #   sponsor_contribution: 50.00,
      # }

      @previous_product           = nil 
      @member_coverage_eligibility_date
    end

    def primary_member
      @members.detect { |member| member.is_primary_member? }
    end

    def add_member(new_member)
      @members << new_member unless is_duplicate_role?(new_member)
    end

    def drop_member(member)
      @members.delete(member)
    end

    def <<(new_member)
      add_member(new_member)
    end

    def [](index)
      @members = index.each { |new_member| add_member(new_member) unless is_duplicate_role?(new_member) }
    end

    def []=(index, new_member)
      @members[index] = new_member unless is_duplicate_role?(new_member)
    end


    private

    def has_primary_member?
      @members.detect { |member| member.is_primary_member? }
    end

    def has_spouse_relationship?
      @members.detect { |member| member.is_spouse_relationship? }
    end

    def has_survivor_member?
      @members.detect { |member| member.is_survivor_member? }
    end

    def is_duplicate_role?(new_member)
      if new_member.is_primary_member? && has_primary_member?
        raise DuplicatePrimaryMemberError, "may have only one primary member"
      end

      if new_member.is_spouse_relationship? && has_spouse_relationship?
        raise MultipleSpouseRelationshipError, "primary member may have only one spouse relationship"
      end

      false
    end

  end

  class DuplicatePrimaryMemberError < StandardError; end
  class MultipleSpouseRelationshipError < StandardError; end
end
