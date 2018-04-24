module BenefitMarkets
    class BenefitMarketFactory
      attr_reader :benefit_market_kind
      
      def initialize(bo_kind)
        @benefit_market_kind = bo_kind
      end

      def allowed_benefit_market_kinds
        ::BenefitMarkets::BenefitMarket::BENEFIT_MARKET_KINDS.map(&:to_s)
      end

      def select_model_subclass
        ::BenefitMarkets::BenefitMarket.subclass_for(benefit_market_kind)
      end

      def build_shared_params(title)
        {
          title: title
        }
      end

      def build_benefit_market(title)
        select_model_subclass.new(
          build_shared_params(title)
        )
      end

      def build_issuer_benefit_market(title)
        select_model_subclass.new(
          build_shared_params(title).merge({
            issuer_id: issuer_id
          })
        )
      end

      def persist(factory_object, e_reporter = nil)
        error_reporter = e_reporter.nil? ? factory_object : e_reporter
        return false unless validate(factory_object, error_reporter)
        factory_object.save.tap do |s_result|
          unless s_result
            factory_object.errors.each do |k, err|
              error_reporter.errors.add(k, err)
            end
          end
        end
      end

      protected

      def validate(benefit_market, error_reporter)
        [

        ]
      end
    end
  end
end
