# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module PremiumCredits
    # This operation is to find Csr value.
    class FindCsrValue
      include Dry::Monads[:result, :do]

      def call(params)
        values = yield validate(params)
        result = yield find_csr_value(values)

        Success(result)
      end

      private

      def validate(params)
        return Failure('Invalid params. missing group_premium_credits') if params[:group_premium_credits].blank?
        return Failure('Invalid params. group_premium_credits should be an instance of Group Premium Credit') if params[:group_premium_credits].any? { |gp| !gp.is_a?(GroupPremiumCredit) }
        return Failure('Missing family member ids') unless params[:family_member_ids]

        Success(params)
      end

      def find_csr_value(values)
        @member_premium_credits = values[:group_premium_credits].collect do |group_premium_credit|
          group_premium_credit.member_premium_credits.csr_eligible.select { |member_premium_credit| values[:family_member_ids].include? member_premium_credit.family_member_id }
        end.flatten

        @csr_hash = @member_premium_credits.inject({}) do |result, member_premium_credit|
          result[member_premium_credit.family_member_id] = member_premium_credit.value
          result
        end

        csr_values = @csr_hash.values.uniq

        handle_native_american_csr

        # TODO: is_ia_eligible doesn't exist on member premium credit.
        any_member_ia_not_eligible = @member_premium_credits.any? { |member_premium_credit| !member_premium_credit.is_ia_eligible }

        csr_value = (any_member_ia_not_eligible || csr_values.blank?) ? 'csr_0' : retrieve_csr(csr_values)

        Success(csr_value)
      end

      def handle_native_american_csr
        return if FinancialAssistanceRegistry.feature_enabled?(:native_american_csr)

        @member_premium_credits.each do |member_premium_credit|
          family_member = member_premium_credit.family_member
          # TODO: is_ia_eligible doesn't exist on member premium credit.
          @csr_hash[family_member.id] = 'csr_limited' if family_member.person.indian_tribe_member && !member_premium_credit.is_ia_eligible
        end

        family_members_with_ai_an = @member_premium_credits.map(&:family_member).select { |fm| fm.person.indian_tribe_member }.map(&:id)
        @member_premium_credits = @member_premium_credits.reject { |member_premium_credit| family_members_with_ai_an.include? member_premium_credit.family_member_id }
      end

      def retrieve_csr(csr_values)
        return 'csr_0' if csr_values.include?('0')
        return 'csr_0' if csr_values.include?('limited') && (csr_values.include?('73') || csr_values.include?('87') || csr_values.include?('94'))
        return 'csr_73' if csr_values.include?('csr_73')
        return 'csr_87' if csr_values.include?('csr_87')
        return 'csr_94' if csr_values.include?('csr_94')
        return 'csr_100' if csr_values.include?('csr_100')
        'csr_0'
      end
    end
  end
end
