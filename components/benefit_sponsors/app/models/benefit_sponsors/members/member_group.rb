# A collection of members, typically a family, who operate as a unit for purposes of benefit coverage
module BenefitSponsors
  class Members::MemberGroup
    include Enumerable
    include ActiveModel::Model

    attr_accessor :group_id, :group_enrollment
    attr_reader :members

    def initialize(opts = {})
      @members          = []
      @group_id         = nil
      @group_enrollment = nil
      @indexed_members = {}
      super(opts)
    end

    def members=(member_list)
      @members = member_list
      @primary_member = @members.detect { |member| member.is_primary_member? }
      @indexed_members = {}
      member_list.each do |m|
        @indexed_members[m.member_id] = m
      end
    end

    def primary_member
      @members.detect { |member| member.is_primary_member? }
    end

    def [](member_id)
      @indexed_members[member_id]
    end

    def remove_members_by_id!(member_id_list)
      cleaned_members = @members.reject do |m|
        member_id_list.include?(m.member_id)
      end
      self.members = cleaned_members
      unless group_enrollment.nil?
        group_enrollment.remove_members_by_id!(member_id_list)
      end
      self
    end

    def each
      @members.each do |m|
        yield m
      end
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
