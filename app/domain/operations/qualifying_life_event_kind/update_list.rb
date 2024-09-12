# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module QualifyingLifeEventKind
    # This class is responsible for updating the order and commonality thresholds of Qualifying Life Event Kind objects
    class UpdateList
      include Dry::Monads[:do, :result]

      def call(input_params)
        persist_data(input_params)
      end

      private

      def persist_data(input_params)
        market_kind = input_params[:params][:market_kind]
        if input_params.dig(:params, :commonality_threshold).present?
          persist_threshold(market_kind, input_params[:params][:commonality_threshold].to_i)
        elsif input_params.dig(:params, :sort_data).present?
          persist_order(market_kind, input_params[:params][:sort_data])
        else
          Failure('Invalid parameters')
        end
      end

      def persist_threshold(market_kind, threshold)
        qleks = ::QualifyingLifeEventKind.where(market_kind: market_kind)
        return Failure("Invalid threshold") unless threshold >= 0 && threshold <= qleks.count

        qleks.each_with_index do |qlek, index|
          qlek.update(is_common: index < threshold)
        end
        Success('Successfully clamped Qualifying Life Event Kind objects on the commonality threshold')
      rescue StandardError => e
        Failure(e.message)
      end

      def persist_order(market_kind, sort_data)
        # TODO: need rake to default threshold
        sort_data.each do |sort|
          qleks = ::QualifyingLifeEventKind.where(market_kind: market_kind, id: sort['id'])
          qleks.update(ordinal_position: sort['position'])
        end

        Success('Successfully sorted Qualifying Life Event Kind objects')
      rescue StandardError => e
        Failure(e.message)
      end
    end
  end
end
