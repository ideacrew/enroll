# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module PremiumCredits
    # This operation is to find Csr value.
    class FindCsrValue
      include Dry::Monads[:do, :result]

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
        subjects = values[:family].eligibility_determination&.subjects&.select { |subject| values[:family_member_ids].map(&:to_s).include? subject.gid.split('/').last } || []

        csr_values = values[:family_member_ids].inject([]) do |csrs, family_member_id|
          csrs << eligibile_csr_value(family_member_id, values[:year], values[:family], subjects)
          csrs
        end

        Success(retrieve_csr(csr_values))
      end

      def fetch_member_csr(family_member_id, year, subjects)
        return '0' if subjects.blank?

        member_subject = subjects.detect { |subj| subj.gid.split('/').last == family_member_id.to_s }
        return '0' if member_subject.blank?

        member_subject.csr_by_year(year) || '0'
      end

      def eligibile_csr_value(family_member_id, year, family, subjects)
        member_csr = fetch_member_csr(family_member_id, year, subjects)
        return member_csr unless FinancialAssistanceRegistry.feature_enabled?(:native_american_csr)

        f_member = family.family_members.where(id: family_member_id).first
        return member_csr unless f_member&.person&.indian_tribe_member

        return member_csr if member_csr == '100'

        'limited'
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
