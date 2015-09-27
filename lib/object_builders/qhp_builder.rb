class QhpBuilder
  LOG_PATH = "#{Rails.root}/log/rake_xml_import_plans_#{Time.now.to_s.gsub(' ', '')}.log"
  LOGGER = Logger.new(LOG_PATH)
  INVALID_PLAN_IDS = ["43849DC0060001", "92479DC0020003"] # These plan ids are suppressed and we dont save these while importing.

  def initialize(qhp_hash)
    @qhp_hash = qhp_hash
    @qhp_array = []
    if qhp_hash[:packages_list].present?
      if qhp_hash[:packages_list][:packages].present?
        @qhp_array = qhp_hash[:packages_list][:packages]
      end
    end
  end

  def add(qhp_hash, file_path)
    temp = qhp_hash[:packages_list][:packages]
    qhp_hash[:packages_list][:packages].each do |package|
      package[:plans_list].deep_merge!(carrier_name: search_carrier_name(file_path))
    end
    @qhp_array = @qhp_array + temp
  end

  def search_carrier_name(file_path)
    file_path = file_path.downcase
    carrier = if file_path.include?("aetna")
      "Aetna"
    elsif file_path.include?("dentegra")
      "Dentegra"
    elsif file_path.include?("delta")
      "Delta Dental"
    elsif file_path.include?("dominion")
      "Dominion"
    elsif file_path.include?("guardian")
      "Guardian"
    elsif file_path.include?("best life")
      "BestLife"
    elsif file_path.include?("metlife")
      "MetLife"
    elsif file_path.include?("united")
      "United Health Care"
    elsif file_path.include?("kaiser")
      "Kaiser"
    elsif file_path.include?("carefirst") || file_path.include?("cf")
      "CareFirst"
    end
  end

  def run
    @xml_plan_counter, @success_plan_counter = 0,0
    iterate_plans
    show_qhp_stats
    mark_2015_dental_plans_as_individual
  end

  def mark_2015_dental_plans_as_individual
    Plan.where(active_year: 2015, coverage_kind: "dental").each do |plan|
      plan.update_attribute(:market, "individual") if plan.coverage_kind == "dental"
    end
  end

  def iterate_plans
    # @qhp_hash[:packages_list][:packages].each do |plans|
    @qhp_array.each do |plans|
      @plans = plans
      @xml_plan_counter += plans[:plans_list][:plans].size
      plans[:plans_list][:plans].each do |plan|
        @plan = plan
        @carrier_name = plans[:plans_list][:carrier_name]
        build_qhp_params
      end
    end
  end

  def build_qhp_params
    build_qhp
    build_benefits
    build_cost_share_variances_list
    validate_and_persist_qhp
  end

  def show_qhp_stats
    puts "*"*80
    puts "Total Number of Plans imported from xml: #{@xml_plan_counter}."
    puts "Total Number of Plans Saved to database: #{@success_plan_counter}."
    puts "Check the log file #{LOG_PATH}"
    puts "*"*80
    LOGGER.info "\nTotal Number of Plans imported from xml: #{@xml_plan_counter}.\n"
    LOGGER.info "\nTotal Number of Plans Saved to database: #{@success_plan_counter}.\n"
  end

  def validate_and_persist_qhp
    begin
      associate_plan_with_qhp
      @qhp.save!
      @success_plan_counter += 1
      LOGGER.info "\nSaved Plan: #{@qhp.plan_marketing_name}, hios product id: #{@qhp.hios_product_id} \n"
    rescue Exception => e
      LOGGER.error "\n Failed to create plan: #{@qhp.plan_marketing_name}, \n hios product id: #{@qhp.hios_product_id} \n Exception Message: #{e.message} \n\n Errors: #{@qhp.errors.full_messages} \n ******************** \n"
    end
  end

  def associate_plan_with_qhp
    effective_date = @qhp.plan_effective_date.to_date
    @qhp.plan_effective_date = effective_date.beginning_of_year
    @qhp.plan_expiration_date = effective_date.end_of_year
    @plan_year = effective_date.year
    if @plan_year > 2015 && !INVALID_PLAN_IDS.include?(@qhp.standard_component_id.strip)
      create_plan_from_serff_data
    end
    candidate_plans = Plan.where(active_year: @plan_year, hios_id: /#{@qhp.standard_component_id.strip}/).to_a
    plan = candidate_plans.sort_by do |plan| plan.hios_id.gsub('-','').to_i end.first
    plans_to_update = Plan.where(active_year: @plan_year, hios_id: /#{@qhp.standard_component_id.strip}/).to_a
    plans_to_update.each do |up_plan|
      nationwide_str = (@qhp.national_network.blank? ? "" : @qhp.national_network)
      nationwide_value = nationwide_str.downcase.strip == "yes"
      up_plan.update_attributes(
          name: @qhp.plan_marketing_name,
          plan_type: @qhp.plan_type.downcase,
          deductible: @qhp.qhp_cost_share_variances.first.qhp_deductable.in_network_tier_1_individual,
          family_deductible: @qhp.qhp_cost_share_variances.first.qhp_deductable.in_network_tier_1_family,
          nationwide: nationwide_value,
          out_of_service_area_coverage: @qhp.out_of_service_area_coverage
      )
      up_plan.save!
    end
    if plan.present?
      @qhp.plan = plan
    else
      puts "Plan Not Saved! Hios: #{@qhp.standard_component_id}, Plan Name: #{@qhp.plan_marketing_name}"
      @qhp.plan = nil
    end
  end

  def create_plan_from_serff_data
    @qhp.qhp_cost_share_variances.each do |cost_share_variance|
      plan = Plan.where(active_year: @plan_year,
        hios_id: /#{@qhp.standard_component_id.strip}/,
        hios_base_id: /#{cost_share_variance.hios_plan_and_variant_id.split('-').first}/,
        csr_variant_id: /#{cost_share_variance.hios_plan_and_variant_id.split('-').last}/).to_a
      next if plan.present?
      new_plan = Plan.new(
        name: @qhp.plan_marketing_name,
        hios_id: cost_share_variance.hios_plan_and_variant_id,
        hios_base_id: cost_share_variance.hios_plan_and_variant_id.split("-").first,
        csr_variant_id: cost_share_variance.hios_plan_and_variant_id.split("-").last,
        active_year: @plan_year,
        metal_level: parse_metal_level,
        market: parse_market,
        ehb: @qhp.ehb_percent_premium,
        # carrier_profile_id: "53e67210eb899a4603000004",
        carrier_profile_id: get_carrier_id(@carrier_name),
        coverage_kind: @qhp.dental_plan_only_ind.downcase == "no" ? "health" : "dental"
        )
      if new_plan.valid?
        new_plan.save!
      end
    end
  end

  def parse_metal_level
    return @qhp.metal_level unless ["high","low"].include?(@qhp.metal_level.downcase)
    @qhp.metal_level = "dental"
  end

  def parse_market
    @qhp.market_coverage = @qhp.market_coverage.downcase.include?("shop") ? "shop" : "individual"
  end

  def get_carrier_id(name)
    CarrierProfile.find_by_legal_name(name)
  end

  def build_qhp
    @qhp = Products::Qhp.new(qhp_params)
  end

  def build_benefits
    benefits_params.each { |benefit| @qhp.qhp_benefits.build(benefit) }
  end

  def build_cost_share_variances_list
    cost_share_variance_list_params.each do |csvp|
      @csvp = csvp
      build_cost_share_variance
    end
  end

  def build_cost_share_variance
    build_sbc_params
    build_moops
    build_service_visits
    build_deductible
  end

  def build_deductible
    @csv.build_qhp_deductable(deductible_params)
  end

  def build_service_visits
    service_visits_params.each do |svp|
      @csv.qhp_service_visits.build(svp)
    end
  end

  def build_moops
    maximum_out_of_pockets_params.each do |moop|
      @csv.qhp_maximum_out_of_pockets.build(moop)
    end
  end

  def build_sbc_params
    @csv = if sbc_params
      @qhp.qhp_cost_share_variances.build(cost_share_variance_attributes.merge(sbc_params))
    else
      @qhp.qhp_cost_share_variances.build(cost_share_variance_attributes)
    end
  end

  def service_visits_params
    @csvp[:service_visits_attributes]
  end

  def deductible_params
    @csvp[:deductible_attributes]
  end

  def maximum_out_of_pockets_params
    @csvp[:maximum_out_of_pockets_attributes]
  end

  def sbc_params
    @csvp[:sbc_attributes]
  end

  def cost_share_variance_attributes
    @csvp[:cost_share_variance_attributes]
  end

  def cost_share_variance_list_params
    @plan[:cost_share_variance_list_attributes]
  end

  def benefits_params
    @plans[:benefits_list][:benefits]
  end

  def qhp_params
    header_params.merge(plan_attribute_params)
  end

  def header_params
    @plans[:header]
  end

  def plan_attribute_params
    assign_active_year_to_qhp
    @plan[:plan_attributes]
  end

  def assign_active_year_to_qhp
    @plan[:plan_attributes][:active_year] = @plan[:plan_attributes][:plan_effective_date][-4..-1].to_i
  end

end
