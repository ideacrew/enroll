# frozen_string_literal: true

module Insured
  module Forms
    class EnrollmentForm
      include Virtus.model

      attribute :covered_members_first_names, Array
      attribute :current_premium,             String
      attribute :effective_on,                Date
      attribute :hbx_id,                      String
      attribute :id,                          String
      attribute :should_term_or_cancel_ivl,   String


      def special_enrollment_period
        HbxEnrollment.where(id: id).first&.special_enrollment_period
      end
    end
  end
end
