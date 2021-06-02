# frozen_string_literal: true

module Operations
  module Products
    # This class is to fetch second lowest cost silver plan.
    class FetchSlcsp
      include Dry::Monads[:result, :do]


      # @param [Date] effective_date
      # @param [Family] family
      # @param [Family Member Id] family member id - to get specific family members slcsp.

      def call(params)
        values            = yield validate(params)
        member_premiums   = yield fetch_member_premiums(values[:family], values[:effective_date])
        slcsp_info        = yield fetch_slcsp_info(member_premiums, values[:family_member_id])

        Success(slcsp_info)
      end

      private

      def validate(params)
        return Failure('Missing Family') if params[:family].blank?
        return Failure('Missing Effective Date') if params[:effective_date].blank?
        Success(params)
      end

      def fetch_member_premiums(family, effective_date)
        Operations::Products::FetchSilverProductPremiums.new.call({family: family, effective_date: effective_date})
      end

      def fetch_slcsp_info(member_premiums, family_member_id)
        if family_member_id.present?
          if member_premiums[family_member_id.to_s].blank?
            return Failure('Could Not find any member premiums for the given data')
          else
            slcsp_info = member_premiums[family_member_id.to_s][0]
          end
        else
          slcsp_info = member_premiums.collect do |fm_id, premiums|
            { fm_id => premiums[1] }
          end
        end

        Success(slcsp_info)
      end
    end
  end
end
