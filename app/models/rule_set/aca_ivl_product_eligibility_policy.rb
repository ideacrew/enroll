# frozen_string_literal: true

module RuleSet
  class AcaIvlProductEligibilityPolicy
    include BenefitMarkets::BusinessRulesEngine

    VALID_PRODUCT_CLASS = ::BenefitMarkets::Products::HealthProducts::HealthProduct
    VALID_MARKET_KIND = :aca_individual
    VALID_METAL_LEVEL_SET = VALID_PRODUCT_CLASS::METAL_LEVEL_KINDS - [:catastrophic]

    rule  :market_kind_eligiblity,
          validate: ->(product){ product.benefit_market_kind == VALID_MARKET_KIND },
          success: ->(_product) { 'validated successfully' },
          fail: ->(product) { "Market Kind of given product is #{product.benefit_market_kind} and not #{VALID_MARKET_KIND}" }

    rule  :product_kind_eligibility,
          validate: ->(product){ product.is_a?(VALID_PRODUCT_CLASS) },
          success: ->(_product) { 'validated successfully' },
          fail: ->(product) { "The given product is of kind #{product.class} and not #{VALID_PRODUCT_CLASS}" }

    rule  :metal_level_eligibility,
          validate: ->(product){ VALID_METAL_LEVEL_SET.include?(product.metal_level_kind) },
          success: ->(_product) {'validated successfully'},
          fail: ->(product) { "Metal Level of the given product is #{product.metal_level_kind} and not one of the #{VALID_METAL_LEVEL_SET}" }

    business_policy :apply_aptc,
                    rules: [:market_kind_eligiblity,
                            :product_kind_eligibility,
                            :metal_level_eligibility]

    def business_policies_for(product, event_name)
      return unless product.is_a?(::BenefitMarkets::Products::Product)

      case event_name
      when :apply_aptc
        business_policies[:apply_aptc]
      end
    end
  end
end