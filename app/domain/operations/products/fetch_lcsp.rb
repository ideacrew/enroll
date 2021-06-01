# frozen_string_literal: true

module Operations
  module Products
    # This class is to fetch lowest cost silver plan.
    class FetchLcsp
      include Dry::Monads[:result, :do]


      # @param [Date] effective_date
      # @param [Family] family
      # @param [Family Member Id] family member id - to get specific family members lcsp.

      def call(params)
        values            = yield validate(params)
        member_premiums   = yield fetch_member_premiums(values[:family], values[:effective_date])
        lcsp_info        = yield fetch_lcsp_info(member_premiums, values[:family_member_id])

        Success(lcsp_info)
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

      def fetch_lcsp_info(member_premiums, family_member_id)
        if family_member_id.present?
          if member_premiums[family_member_id].blank?
            return Failure('Could Not find any member premiums for the given data')
          else
            lcsp_info = member_premiums[:family_member_id][0]
          end
        else
          lcsp_info = member_premiums.collect do |fm_id, premiums|
            { fm_id => premiums[0] }
          end
        end

        Success(lcsp_info)
      end
    end
  end
end
