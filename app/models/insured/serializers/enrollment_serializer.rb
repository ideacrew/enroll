# frozen_string_literal: true

module Insured
  module Serializers
    class EnrollmentSerializer < ::ActiveModel::Serializer
      attributes :id, :hbx_id, :effective_on
      attribute :covered_members_first_names
      attribute :should_term_or_cancel_ivl

      def covered_members_first_names
        object.hbx_enrollment_members.inject([]) do |names, member|
          names << member.person.first_name
        end
      end

      def should_term_or_cancel_ivl
        if object.effective_on > TimeKeeper.date_of_record
          'cancel'
        elsif (object.effective_on <= TimeKeeper.date_of_record || object.may_terminate_coverage?)
          'terminate'
        end
      end

      # provide defaults(if any needed) that were not set on Model
      def attributes(*args)
        hash = super
        unless object.persisted?

        end
        hash
      end
    end
  end
end
