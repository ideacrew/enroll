module BenefitSponsors
  class Members::MemberRoster

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
      @member_groups[index]
    end

    def []=(index, new_member_group)
      @member_groups[index] = new_member_group
    end


  end
end
