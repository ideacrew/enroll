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
        return Failure('Missing family member ids') unless params[:family_member_ids]
        return Failure('Missing family') unless params[:family]
        return Failure('Missing year') unless params[:year]

        Success(params)
      end

      def find_csr_value(values)
        @subjects = values[:family].eligibility_determination&.subjects&.select { |subject| values[:family_member_ids].include? subject.gid.split('/').last } || []

        @csr_hash = @subjects.inject({}) do |result, subject|
          result[subject.gid.split('/').last] = subject.csr_by_year(values[:year])
          result
        end

        any_member_ia_not_eligible = values[:family_member_ids].any? { |family_member_id| @csr_hash[family_member_id].nil? }

        handle_native_american_csr

        csr_values = @csr_hash.values.uniq

        csr_value = (any_member_ia_not_eligible || csr_values.blank?) ? 'csr_0' : retrieve_csr(csr_values)

        Success(csr_value)
      end

      def handle_native_american_csr
        return unless FinancialAssistanceRegistry.feature_enabled?(:native_american_csr)

        @subjects.each do |subject|
          @csr_hash[subject.gid.split('/').last] = 'limited' if subject.person.indian_tribe_member
        end
      end

      # rubocop:disable Metrics/CyclomaticComplexity
      def retrieve_csr(csr_values)
        return 'csr_0' if csr_values.include?('0')
        return 'csr_0' if csr_values.include?('limited') && (csr_values.include?('73') || csr_values.include?('87') || csr_values.include?('94'))
        return 'csr_limited' if csr_values.include?('limited')
        return 'csr_73' if csr_values.include?('73')
        return 'csr_87' if csr_values.include?('87')
        return 'csr_94' if csr_values.include?('94')
        return 'csr_100' if csr_values.include?('100')
        'csr_0'
      end
      # rubocop:enable Metrics/CyclomaticComplexity
    end
  end
end
