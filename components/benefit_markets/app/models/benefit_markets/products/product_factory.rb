module BenefitMarkets
  class Products::ProductFactory

    attr_accessor :date, :product

    def initialize(options = {})
      @date = options[:data] if options[:data]
      product_for(options[:product_id])
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

    def cost_for(schedule_date, age)
      bound_age_val = bound_age(age)
      value = premium_table_for(schedule_date).first.premium_tuples.detect {|pt| pt.age == bound_age_val}.cost
      BigDecimal.new("#{value}").round(2).to_f
    rescue StandardError
      raise [(product.id if product), bound_age_val, schedule_date, age].inspect
    end

    def bound_age(age)
      return product.premium_ages.min if age < product.premium_ages.min
      return product.premium_ages.max if age > product.premium_ages.max

      age
    end

    def premium_table_for(date)
      product.premium_tables.select do |pt|
        (pt.effective_period.min <= date) && (pt.effective_period.max >= date)
      end
    end

    def product_for(id)
      @product = BenefitMarkets::Products::Product.find(id) if id
    end
  end
end
