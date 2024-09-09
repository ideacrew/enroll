# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module QualifyingLifeEventKind
    class Sort
      include Dry::Monads[:do, :result]

      def call(input_params)
        persist_data(input_params[:params])
      end

      private

      def persist_data(params)
        sort_data = params['sort_data']

        # default for now
        commonality_threshold = 10
        sort_data.each do |sort|
          qleks = ::QualifyingLifeEventKind.where(market_kind: params['market_kind'], id: sort['id'])
          is_common = sort['position'].to_i <= commonality_threshold
          qleks.update(ordinal_position: sort['position'], is_common: is_common)
        end

        Success('Successfully sorted Qualifying Life Event Kind objects')
      end
    end
  end
end
