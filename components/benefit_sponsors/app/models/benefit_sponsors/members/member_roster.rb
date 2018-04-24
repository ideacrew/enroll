module BenefitSponsors
  class Members::MemberRoster

    attr_reader :member_groups

    def initialize
      @member_groups = []
    end

    def add_member_group(new_member_group)
      @member_groups << new_member_group
    end

    def drop_member_group(member_group)
      @member_groups.delete(member_group)
    end

    def <<(new_member_group)
      add_member_group(new_member_group)
    end

    def [](index)
      # @member_groups[index]
      @member_groups = index.each { |new_member_group| add_member(new_member_group) }
      
    end

    def []=(index, new_member_group)
      @member_groups[index] = new_member_group
    end


  end
end
