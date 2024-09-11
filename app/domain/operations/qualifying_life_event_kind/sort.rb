# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module QualifyingLifeEventKind
    class Sort
      include Dry::Monads[:do, :result]

      def call(input_params)
        if input_params[:params].key?('commonality_threshold')
          persist_threshold(input_params[:params])
        else
          persist_qles(input_params[:params])
        end
      end

      private

      def persist_threshold(params)
        threshold = params['commonality_threshold'].to_i
        ::QualifyingLifeEventKind.where(market_kind: params['market_kind']).each_with_index do |qlek, index|
          qlek.update(is_common: index < threshold)
        end
      rescue StandardError => e
        Failure(e.message)
      end

      def persist_qles(params)
        sort_data = params['sort_data']

        # default for now
        commonality_threshold = params['commonality_threshold']&.to_i || 10

        sort_data.each do |sort|
          qleks = ::QualifyingLifeEventKind.where(market_kind: params['market_kind'], id: sort['id'])
          is_common = sort['position'].to_i <= commonality_threshold
          qleks.update(ordinal_position: sort['position'], is_common: is_common)
        end

        Success('Successfully sorted Qualifying Life Event Kind objects')
      rescue StandardError => e
        Failure(e.message)
      end
    end
  end
end
