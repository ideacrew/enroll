module BenefitMarkets
  class Products::ProductFactory

    attr_accessor :date

    def initialize(param)
      @date = param
    end

    def has_rates?
      return false if @date.blank?

      date_range = @date.beginning_of_month..@date.end_of_month
      # searches products by date_range, filters with health products and then
      # checks if premium_tables are present for that effective_date.
      ::BenefitMarkets::Products::Product
        .by_application_period(date_range)
        .health_products
        .effective_with_premiums_on(@date)
        .present?
    end
  end
end
