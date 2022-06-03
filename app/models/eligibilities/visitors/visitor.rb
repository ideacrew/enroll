# frozen_string_literal: true

module Eligibilities
  module Visitors
  # Interface for Eligibility Visitors
    class Visitor
      include Config::SiteHelper
      def visit(subject); end

      def self.get_evidence_on(evidence_key, date); end

    end
  end
end
