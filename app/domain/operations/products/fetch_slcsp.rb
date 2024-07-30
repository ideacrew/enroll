# frozen_string_literal: true

module Operations
  module Products
    # This class is to fetch Second Lowest Cost Silver Plan. (SLCSP)
    class FetchSlcsp
      include Dry::Monads[:do, :result]
      # @param [Hash of member premiums for silver plans] member_silver_product_premiums

      def call(params)
        values                     = yield validate(params)
        slcsp_info                 = yield fetch_slcsp_info(values[:member_silver_product_premiums])
        transformed_slcsp_info     = yield transform(slcsp_info)

        Success(transformed_slcsp_info)
      end

      private

      def validate(params)
        return Failure('Missing Silver Products Member Premiums') if params[:member_silver_product_premiums].blank?

        Success(params)
      end

      def fetch_slcsp_info(member_premiums)
        slcsp_info = {}
        member_premiums.each_pair do |address_ids, premiums|
          slcsp_info[address_ids] = {}
          premiums.each_pair do |type, mem_values|
            slcsp_info[address_ids][type] = {}
            mem_values.each_pair do |fm_id, values|
              slcsp_info[address_ids][type][fm_id] = values[1] || values[0]
            end
          end
        end

        Success(slcsp_info)
      end

      def transform(slcsp_info)
        result = {}

        slcsp_info.each_pair do |person_hbx_ids, premiums|
          person_hbx_ids.each do |hbx_id|
            premium_hash = {}
            premium_hash[:health_only_slcsp_premiums] = premiums[:health_only].values.compact.find {|v| v[:member_identifier].to_s == hbx_id} if premiums[:health_only].present?
            premium_hash[:health_and_dental_slcsp_premiums] = premiums[:health_and_dental].values.compact.find {|v| v[:member_identifier].to_s == hbx_id} if premiums[:health_and_dental].present?
            premium_hash[:health_and_ped_dental_slcsp_premiums] = premiums[:health_and_ped_dental].values.compact.find {|v| v[:member_identifier].to_s == hbx_id} if premiums[:health_and_ped_dental].present?

            result[hbx_id] = premium_hash
          end
        end

        incomplete_results = result.find_all do |_hbx_id, premium_hash|
          premium_hash[:health_only_slcsp_premiums].blank? &&
            premium_hash[:health_and_dental_slcsp_premiums].blank? &&
            premium_hash[:health_and_ped_dental_slcsp_premiums].blank?
        end

        if incomplete_results.empty?
          Success(result)
        else
          Failure("Could not calculate SLCS premiums for #{incomplete_results.map(&:first).join(' ')}")
        end
      end
    end
  end
end
