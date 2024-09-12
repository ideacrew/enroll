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
        @qleks = ::QualifyingLifeEventKind.where(market_kind: input_params[:params][:market_kind]).active_by_state
        if input_params.dig(:params, :commonality_threshold).present?
          persist_threshold(input_params[:params][:commonality_threshold].to_i)
        elsif input_params.dig(:params, :sort_data).present?
          persist_order(input_params[:params][:sort_data])
        else
          Failure('Invalid parameters')
        end
      end

      def persist_threshold(threshold)
        return Failure("Invalid threshold") unless threshold >= 0 && threshold <= @qleks.count

        @qleks.each_with_index do |qlek, index|
          qlek.update(is_common: index < threshold)
        end

        Success('Successfully clamped Qualifying Life Event Kind objects on the commonality threshold')
      rescue StandardError => e
        Failure(e.message)
      end

      def persist_order(sort_data)
        threshold = @qleks.common.count
        threshold = 10 if @qleks.all? { |qlek| qlek.is_common.nil? }

        @qleks.each do |qlek|
          position = sort_data.find { |sort| sort['id'] == qlek.id.to_s }['position']
          qlek.update(ordinal_position: position, is_common: position - 1 < threshold)
        end

        Success('Successfully sorted Qualifying Life Event Kind objects')
      rescue StandardError => e
        Failure(e.message)
      end
    end
  end
end
