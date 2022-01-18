# frozen_string_literal: true

module Eligibilities
  module Visitors
    # Visitor mixin
    module Visitable
      def accept(visitor); end
    end
  end
end
