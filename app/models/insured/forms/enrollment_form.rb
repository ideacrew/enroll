# frozen_string_literal: true

module Insured
  module Forms
    class EnrollmentForm
      include Virtus.model

      attribute :covered_members_first_names, Array
      attribute :effective_on,                Date
      attribute :hbx_id,                      String
      attribute :id,                          String
      attribute :should_term_or_cancel_ivl,   String
    end
  end
end
