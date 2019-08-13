# frozen_string_literal: true

module Insured
  module Forms
    class EnrollmentForm
      include Virtus.model

      attribute :id,           String
      attribute :hbx_id,       String
      attribute :effective_on, Date
    end
  end
end
