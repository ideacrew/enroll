# frozen_string_literal: true

module Operations
  module Products
    # This class is to load county zip combinations.
    class AgeLookup
      include Dry::Monads[:do, :result]

      def call(age)
        # TODO: read the lowest and highest ages from Settings/DB.
        # These values are not constant for all the exchanges - need to update
        lowest_age_for_premium_lookup = 14
        highest_age_for_premium_lookup = 64

        output =
          if age <= lowest_age_for_premium_lookup
            lowest_age_for_premium_lookup
          elsif age >= highest_age_for_premium_lookup
            highest_age_for_premium_lookup
          else
            age
          end

        Success(output)
      end
    end
  end
end
