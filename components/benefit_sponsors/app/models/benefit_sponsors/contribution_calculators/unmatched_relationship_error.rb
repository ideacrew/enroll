module BenefitSponsors
  module ContributionCalculators
    class UnmatchedRelationshipError < RangeError
      include Acapi::Notifier

      attr_reader :primary_id
      attr_reader :member_id
      attr_reader :relationship

      def initialize(primary_id, member_id, relationship)
        @primary_id = primary_id
        @member_id = member_id
        @relationship = relationship
        super(message)
      end

      def message
        "Invalid Relationship for contribution calculations: person_id: #{primary_id}, relationship: #{relation_string}, member: #{member_id}"
      end

      def broadcast
        log("#47977 Invalid Relationship for contribution calculations: person_id: #{primary_id}, relationship: #{relation_string}, member: #{member_id}", {:severity => "error"})
      end
    end
  end
end