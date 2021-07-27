# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module Families
    # FindFamilyMember
    class FindFamilyMember
      send(:include, Dry::Monads[:result, :do])

      def call(*args); end

      private

      def validate(id); end

      def find_family(family_member_id); end

    end
  end
end
