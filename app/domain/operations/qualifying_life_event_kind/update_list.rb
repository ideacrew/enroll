# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module QualifyingLifeEventKind
    # This class is responsible for updating and persisting the QualifyingLifeEventKind list based on two sub-operations:
    # 1. Updating the commonality threshold, which sets the `is_common` attribute of the objects bassed on the threshold index param.
    # 2. Updating the order, which mainly sets the `ordinal_position` attribute of the objects based on the sort_data param,
    # and also updates `is_common` attribute of the objects based on the new order.
    class UpdateList
      include Dry::Monads[:do, :result]

      # Updates the QLEK object list based on the params.
      def call(input_params)
        persist_data(input_params)
      end

      private

      # @method persist_data(input_params)
      # Saves the QualifyingLifeEventKind list based on the input parameters:
      # When the params contain a commonality threshold, the QLEK objects are clamped on the threshold.
      # When the params contain sort data, the QLEK objects are sorted based on the position.
      #
      # @param [Hash] input_params The params used to save the QLEK list.
      #
      # @return [Result]
      #   returns a Success if the save operation suceeded.
      #   returns a Failure if the save operation failed.
      def persist_data(input_params)
        market_kind = input_params.dig(:params, 'market_kind')
        return Failure('Invalid parameters') if market_kind.nil?

        @qleks = ::QualifyingLifeEventKind.where(market_kind: market_kind).active_by_state

        commonality_threshold_param = input_params.dig(:params, 'commonality_threshold')&.to_i
        sort_data_param = input_params.dig(:params, 'sort_data')
        if commonality_threshold_param.present?
          persist_threshold(commonality_threshold_param)
        elsif sort_data_param.present?
          persist_order(sort_data_param)
        else
          Failure('Invalid parameters')
        end
      rescue StandardError => e
        Failure(e.message)
      end

      # @method persist_threshold(threshold)
      # Clamps the QLEK objects on the commonality threshold by updating the `is_common` attribute based on the index, and save.
      #
      # @param [Integer] threshold The "commonality" index separating common and uncommon QLEK objects.
      #
      # @return [Result]
      #   returns a Success if the QLEK objects were successfully clamped on the threshold and saved.
      #   returns a Failure if the save operation failed.
      def persist_threshold(threshold)
        return Failure("Invalid threshold") unless threshold >= 1 && threshold <= @qleks.count

        @qleks.each_with_index do |qlek, index|
          qlek.update(is_common: index < threshold)
        end

        Success('Successfully clamped Qualifying Life Event Kind objects on the commonality threshold')
      rescue StandardError => e
        Failure(e.message)
      end

      # Sorts the QLEK objects based on the sort data by updating the `ordinal_position` attributes, and save.
      # This will also update the `is_common` attribute based on the saved threshold, as the new order may change where some QLEKs are relative to the threshold.
      #
      # @method persist_order(sort_data)
      # Clamps the QLEK objects on the commonality threshold by updating the `is_common` attribute based on the index, and save.
      #
      # @param [Array] sort_data The array of QLEK object ids and their new positions.
      #
      # @return [Result]
      #   returns a Success if the QLEK objects were successfully sorted and saved.
      #   returns a Failure if the save operation failed.
      def persist_order(sort_data)
        threshold = @qleks.common.count

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
