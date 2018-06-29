module BenefitSponsors
  module ConfigurationHelper
    def plan_match_tool_is_enabled?
      true
    end

    def aca_shop_market_census_employees_template_file
      @aca_shop_market_census_employees_template_file ||= 'fix me'
    end

    def site_short_name
      'mch'
    end
  end
end
