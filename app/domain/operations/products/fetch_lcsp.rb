# frozen_string_literal: true

module Operations
  module Products
    # This class is to fetch lowest cost silver plan.
    class FetchLcsp
      include Dry::Monads[:do, :result]
      # @param [Hash of member premiums for silver plans] member_silver_product_premiums

      def call(params)
        values = yield validate(params)
        lcsp_info                 = yield fetch_lcsp_info(values[:member_silver_product_premiums])
        transformed_lcsp_info     = yield transform(lcsp_info)

        Success(transformed_lcsp_info)
      end

      private

      def validate(params)
        return Failure('Missing Silver Products Member Premiums') if params[:member_silver_product_premiums].blank?

        Success(params)
      end

      def fetch_lcsp_info(member_premiums)
        lcsp_info = {}
        member_premiums.each_pair do |address_ids, premiums|
          lcsp_info[address_ids] = {}
          premiums.each_pair do |type, mem_values|
            lcsp_info[address_ids][type] = {}
            mem_values.each_pair do |fm_id, values|
              lcsp_info[address_ids][type][fm_id] = values[0]
            end
          end
        end

        Success(lcsp_info)
      end

      def transform(lcsp_info)
        result = {}

        lcsp_info.each_pair do |person_hbx_ids, premiums|
          person_hbx_ids.each do |hbx_id|
            premium_hash = {}
            premium_hash[:health_only_lcsp_premiums] = premiums[:health_only].values.compact.find {|v| v[:member_identifier].to_s == hbx_id} if premiums[:health_only].present?
            premium_hash[:health_and_dental_lcsp_premiums] = premiums[:health_and_dental].values.compact.find {|v| v[:member_identifier].to_s == hbx_id} if premiums[:health_and_dental].present?
            premium_hash[:health_and_ped_dental_lcsp_premiums] = premiums[:health_and_ped_dental].values.compact.find {|v| v[:member_identifier].to_s == hbx_id} if premiums[:health_and_ped_dental].present?

            result[hbx_id] = premium_hash
          end
        end

        incomplete_results = result.find_all do |_hbx_id, premium_hash|
          premium_hash[:health_only_lcsp_premiums].blank? &&
            premium_hash[:health_and_dental_lcsp_premiums].blank? &&
            premium_hash[:health_and_ped_dental_lcsp_premiums].blank?
        end

        if incomplete_results.empty?
          Success(result)
        else
          Failure("Could not calculate LCS premiums for #{incomplete_results.map(&:first).join(' ')}")
        end
      end
    end
  end
end
