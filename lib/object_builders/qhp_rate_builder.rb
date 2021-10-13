class QhpRateBuilder

  INVALID_PLAN_IDS = ["78079DC0320003","78079DC0320004","78079DC0340002","78079DC0330002"]
  METLIFE_HIOS_IDS = ["43849DC0090001", "43849DC0080001"]

  def initialize
    @rating_method = 'Age-Based Rates'
    @rates_array = []
    @results_array = []
    @rating_area_id_cache = {}
    @rating_area_cache = {}
    @premium_table_cache = Hash.new {|h, k| h[k] = Hash.new}
    @action = "new"
  end

  def set_rating_area_cache
    ::BenefitMarkets::Locations::RatingArea.all.each do |ra|
      @rating_area_id_cache[[ra.active_year, ra.exchange_provided_code]] = ra.id
      @rating_area_cache[ra.id] = ra
    end
  end

  def add(rates_hash, action, year)
    set_rating_area_cache
    if year < 2018
      @rates_array = @rates_array + rates_hash[:items]
      @action = action
    else
      rates_hash[:plan_rate_group_attributes].each do |rate_group_attributes|
        @rating_method = rate_group_attributes[:rating_method]
        @rates_array += assign_rating_method(rate_group_attributes[:items])
        @action = action
      end
    end
  end

  def assign_rating_method(item_attributes)
    item_attributes.each do |item|
      item[:rating_method] = @rating_method
    end
  end

  def run
    @results = Hash.new{|results,k| results[k] = []}
    @rates_array.each do |rate|
      @rate = rate
      build_premium_tables
      build_product_premium_tables
    end
    if @action == "new"
      find_qhp_and_create_premium_tables
      find_plan_and_create_premium_tables if EnrollRegistry.feature_enabled?(:has_bqt)
      find_product_and_create_premium_tables
    else
      find_plan_and_update_premium_tables
    end
  end

  def find_qhp_and_create_premium_tables
    @qhp_rates_hash = Hash.new {|h, k| h[k] = []}
    @rates_array.each do |rate|
      @qhp_rates_hash[rate[:plan_id]] << rate.except(:rating_method)
    end
    @qhp_rates_hash.each do |hios_id, qhp_rates|
      qhp = Products::Qhp.where(active_year: qhp_rates.first[:effective_date].to_date.year, standard_component_id: hios_id).first

      next if qhp.blank?

      qhp.qhp_premium_tables = [] if qhp.qhp_premium_tables.present?
      rates = []
      qhp_rates.each do |qhp_rate|
        qhp_rate_attributes = {
          rate_area_id: qhp_rate[:rate_area_id].gsub("Rating Area ", "R-#{EnrollRegistry[:enroll_app].setting(:state_abbreviation).item.upcase}00"),
          plan_id: qhp_rate[:plan_id],
          tobacco: qhp_rate[:tobacco],
          effective_date: qhp_rate[:effective_date],
          expiration_date: qhp_rate[:expiration_date],
          age_number: assign_age(qhp_rate[:age_number]),
          primary_enrollee: qhp_rate[:primary_enrollee],
          couple_enrollee: qhp_rate[:couple_enrollee],
          couple_enrollee_one_dependent: qhp_rate[:couple_enrollee_one_dependent],
          couple_enrollee_two_dependent: qhp_rate[:couple_enrollee_two_dependent],
          couple_enrollee_many_dependent: qhp_rate[:couple_enrollee_many_dependent],
          primary_enrollee_one_dependent: qhp_rate[:primary_enrollee_one_dependent],
          primary_enrollee_two_dependent: qhp_rate[:primary_enrollee_two_dependent],
          primary_enrollee_many_dependent: qhp_rate[:primary_enrollee_many_dependent],
          is_issuer_data: qhp_rate[:is_issuer_data],
          primary_enrollee_tobacco: qhp_rate[:primary_enrollee_tobacco]
        }
        rates << qhp_rate_attributes
      end
      qhp.qhp_premium_tables = rates
      qhp.save
    end
  end

#metlife has a different format for importing rate templates.
  def calculate_and_build_metlife_premium_tables
    (20..65).each do |metlife_age|
      @metlife_age = metlife_age
      key = "#{@rate[:plan_id]},#{@rate[:effective_date].to_date.year}"
      rating_area = @rate[:rate_area_id].gsub("Rating Area ", "R-DC00")
      @results[key] << {
        age: metlife_age,
        start_on: @rate[:effective_date],
        end_on: @rate[:expiration_date],
        cost: calculate_metlife_cost,
        rating_area: rating_area
      }
    end
  end

  def calculate_metlife_cost
    if @metlife_age == 20
      (@rate[:primary_enrollee_one_dependent].to_f - @rate[:primary_enrollee].to_f).round(2)
    else
      @rate[:primary_enrollee].to_f
    end
  end

  def build_premium_tables
    if METLIFE_HIOS_IDS.include?(@rate[:plan_id])
      calculate_and_build_metlife_premium_tables
    else
      key = "#{@rate[:plan_id]},#{@rate[:effective_date].to_date.year}"
      rating_area = @rate[:rate_area_id].gsub("Rating Area ", "R-#{EnrollRegistry[:enroll_app].setting(:state_abbreviation).item.upcase}00")
      attrs = {
        start_on: @rate[:effective_date],
        end_on: @rate[:expiration_date],
        cost: @rate[:primary_enrollee],
        rating_area: rating_area
      }

      attrs.merge!({tobacco_cost: @rate[:primary_enrollee_tobacco]}) if ::EnrollRegistry.feature_enabled?(:tobacco_cost)

      if assign_age(@rate[:age_number]).zero?
        (14..64).each do |age|
          @results[key] << attrs.merge!({age: age})
          @results[key]
        end
      else
        @results[key] << attrs.merge!({age: assign_age(@rate[:age_number])})
        @results[key]
      end
    end
  end

  def find_product_and_create_premium_tables
    @results_array.uniq.each do |value|
      hios_id, year = value.split(",")
      products = ::BenefitMarkets::Products::Product.where(hios_id: /#{hios_id}/).select{|a| a.active_year.to_s == year.to_s}
      products.each do |product|
        product.premium_tables = nil
        product.save
      end
    end
    @premium_table_cache.each_pair do |k, v|
      product_hios_id, rating_area_id, applicable_range, rating_method = k
      premium_tables = []
      premium_tuples = []

      v.each_pair do |pt_age, pt_cost|
        cost, tobacco_cost = pt_cost.split(";")
        premium_tuples_params = {age: pt_age, cost: cost}
        premium_tuples_params.merge!(tobacco_cost: tobacco_cost) if ::EnrollRegistry.feature_enabled?(:tobacco_cost)
        premium_tuples << ::BenefitMarkets::Products::PremiumTuple.new(premium_tuples_params)
      end

      premium_tables << ::BenefitMarkets::Products::PremiumTable.new(
        effective_period: applicable_range,
        rating_area: @rating_area_cache[rating_area_id],
        rating_area_id: rating_area_id,
        premium_tuples: premium_tuples
      )

      active_year = applicable_range.first.year
      products = ::BenefitMarkets::Products::Product.where(hios_id: /#{product_hios_id}/).select{|a| a.active_year == active_year}
      products.each do |product|
        product.rating_method = rating_method
        product.premium_tables << premium_tables
        product.premium_ages = premium_tuples.map(&:age).minmax
        product.save
      end
    end
  end

  def build_product_premium_tables
    active_year = @rate[:effective_date].to_date.year
    applicable_range = @rate[:effective_date].to_date..@rate[:expiration_date].to_date
    rating_area = @rate[:rate_area_id].gsub("Rating Area ", "R-#{EnrollRegistry[:enroll_app].setting(:state_abbreviation).item.upcase}00")
    rating_area_id = @rating_area_id_cache[[active_year, rating_area]]

    if assign_age(@rate[:age_number]).zero?
      (14..64).each do |age|
        @premium_table_cache[[@rate[:plan_id], rating_area_id, applicable_range, @rate[:rating_method]]][age] = "#{@rate[:primary_enrollee]};#{@rate[:primary_enrollee_tobacco]}"
      end
    else
      @premium_table_cache[[@rate[:plan_id], rating_area_id, applicable_range, @rate[:rating_method]]][assign_age(@rate[:age_number])] = "#{@rate[:primary_enrollee]};#{@rate[:primary_enrollee_tobacco]}"
    end
    @results_array << "#{@rate[:plan_id]},#{active_year}"
  end

  def assign_age(rate)
    case rate
    when "0-14"
      14
    when "0-20"
      20
    when "64 and over"
      64
    when "65 and over"
      65
    else
      rate.to_i
    end
  end

  def find_plan_and_create_premium_tables
    @results.each do |key, premium_tables|
      hios_id, year = key.split(",")
      unless INVALID_PLAN_IDS.include?(hios_id)
        @plans = Plan.where(hios_id: /#{hios_id}/, active_year: year)
        @plans.each do |plan|
          plan.premium_tables = []
          plan.premium_tables = premium_tables
          plan.minimum_age, plan.maximum_age = plan.premium_tables.map(&:age).minmax
          plan.save
        end
      end
    end
  end

  def find_plan_and_update_premium_tables
    @results.each do |key, premium_tables|
      hios_id, year = key.split(",")
      unless INVALID_PLAN_IDS.include?(hios_id)
        @plans = Plan.where(hios_id: /#{hios_id}/, active_year: year)
        @plans.each do |plan|
          pts = plan.premium_tables
          premium_table_hash.each do |value|
            pt = pts.where(age: value[:age], start_on: value[:start_on], end_on: value[:end_on], rating_area: value[:rating_area]).first
            pt.cost = value[:cost]
            pt.save
          end
        end
      end
    end
  end

end