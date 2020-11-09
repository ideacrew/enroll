class QhpBuilder
  INVALID_PLAN_IDS = ["88806MA0020005", "88806MA0040005", "88806MA0020051",
  "18076MA0010001", "80538MA0020001", "80538MA0020002", "11821MA0020001", "11821MA0040001"] # These plan ids are suppressed and we dont save these while importing.
  BEST_LIFE_HIOS_IDS = ["95051DC0020003", "95051DC0020006", "95051DC0020004", "95051DC0020005"]
  LOG_PATH = "#{Rails.root}/log/rake_xml_import_plans_#{Time.now.to_s.gsub(' ', '')}.log"

  def initialize(qhp_hash)
    @log_path = LOG_PATH
    # @issuer_profile_hash = {}
    # set_issuer_profile_hash
    # @service_area_map = {}
    # set_service_areas
    FileUtils.mkdir_p(File.dirname(@log_path)) unless File.directory?(File.dirname(@log_path))
    @logger = Logger.new(@log_path)

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
    elsif file_path.include?("altus")
      "Altus"
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
      "UnitedHealthcare"
    elsif file_path.include?("kaiser")
      "Kaiser"
    elsif file_path.include?("united")
      "UnitedHealthcare"
    elsif file_path.include?("carefirst") || file_path.include?("cf")
      "CareFirst"
    end
  end

  def run
    @xml_plan_counter, @success_plan_counter = 0,0
    iterate_plans
    show_qhp_stats
    mark_2015_dental_plans_as_individual
    mark_2015_catastrophic_plans_as_individual
    mark_one_2015_plan_as_shop
    remove_2016_metlife_plans
  end

  def remove_2016_metlife_plans
    # deleting metlife plans based on carrier profile id
    Plan.where(active_year: 2016, carrier_profile_id: "53e67210eb899a460300001d").size
  end

  def mark_one_2015_plan_as_shop
    Plan.where(active_year: 2015, hios_id: /94506DC0350012/).each do |plan|
      plan.update_attribute(:market, "shop")
    end
  end

  def mark_2015_catastrophic_plans_as_individual
    Plan.catastrophic_level.by_active_year(2015).each do |plan|
      plan.update_attribute(:market, "individual")
    end
  end

  def mark_2015_dental_plans_as_individual
    # find ivl dental plans that are marked as shop.
    #delete bestone plans as they do not have corresponding serff templates.
    Plan.shop_dental_by_active_year(2015).each do |plan|
      if BEST_LIFE_HIOS_IDS.include?(plan.hios_id)
        plan.destroy
      else
        plan.update_attribute(:market, "individual") if plan.coverage_kind == "dental"
      end
    end
  end

  def update_dental_plans
    Plan.where(:active_year.in => [2015, 2016], coverage_kind: "dental").each do |plan|
      plan.hios_id = plan.hios_base_id
      plan.csr_variant_id = ""
      plan.save
    end
  end

  def iterate_plans
    update_dental_plans
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
    puts "Check the log file #{@log_path}"
    puts "*"*80
    @logger.info "\nTotal Number of Plans imported from xml: #{@xml_plan_counter}.\n"
    @logger.info "\nTotal Number of Plans Saved to database: #{@success_plan_counter}.\n"
  end

  def validate_and_persist_qhp
    begin
      if !INVALID_PLAN_IDS.include?(@qhp.standard_component_id.strip)
        associate_plan_with_qhp
        @qhp.save!
        @success_plan_counter += 1
      end
      @logger.info "\nSaved Plan: #{@qhp.plan_marketing_name}, hios product id: #{@qhp.hios_product_id} \n"
    rescue Exception => e
      @logger.error "\n Failed to create plan: #{@qhp.plan_marketing_name}, \n hios product id: #{@qhp.hios_product_id} \n Exception Message: #{e.message} \n\n Errors: #{@qhp.errors.full_messages} \n\n Backtrace: #{e.backtrace.join("\n            ")}\n ******************** \n"
    end
  end

  def associate_plan_with_qhp
    @dental_metal_level = ""
    effective_date = @qhp.plan_effective_date.to_date
    @qhp.plan_effective_date = effective_date.beginning_of_year
    @qhp.plan_expiration_date = effective_date.end_of_year
    @plan_year = effective_date.year

    @dental_metal_level = @qhp.metal_level.downcase if @qhp.dental_plan_only_ind.downcase == "yes"
    create_plan_from_serff_data
    # create_product_from_serff_data

    candidate_plans = Plan.where(active_year: @plan_year, hios_id: /#{@qhp.standard_component_id.strip}/).to_a
    plan = candidate_plans.sort_by do |plan| plan.hios_id.gsub('-','').to_i end.first
    plans_to_update = Plan.where(active_year: @plan_year, hios_id: /#{@qhp.standard_component_id.strip}/).to_a
    plans_to_update.each do |up_plan|
      nation_wide, dc_in_network = parse_nation_wide_and_dc_in_network
      up_plan.update_attributes(
          # name: @qhp.plan_marketing_name.squish!,
          hios_id: up_plan.coverage_kind == "dental" ? up_plan.hios_id.split("-").first : up_plan.hios_id,
          hios_base_id: up_plan.hios_id.split("-").first,
          # csr_variant_id: up_plan.hios_id.include?("-") ? up_plan.hios_id.split("-").last : "",
          csr_variant_id: up_plan.coverage_kind == "dental" ? "" : up_plan.hios_id.split("-").last,
          plan_type: @qhp.plan_type.downcase,
          deductible: @qhp.qhp_cost_share_variances.first.qhp_deductable.in_network_tier_1_individual,
          family_deductible: @qhp.qhp_cost_share_variances.first.qhp_deductable.in_network_tier_1_family,
          nationwide: nation_wide,
          dc_in_network: dc_in_network,
          dental_level: @dental_metal_level
      )
      up_plan.save!
    end
    if plan.present?
      @qhp.plan = plan
    else
      puts "Plan Not Saved! Year: #{@qhp.active_year} :: Hios: #{@qhp.standard_component_id}, Plan Name: #{@qhp.plan_marketing_name}"
      @qhp.plan_id = nil
      # @qhp.plan = nil
    end
  end

  def parse_nation_wide_and_dc_in_network
    if @qhp.national_network.downcase.strip == "yes"
      ["true", "false"]
    else
      ["false", "true"]
    end
  end

  def create_plan_from_serff_data
    @qhp.qhp_cost_share_variances.each do |cost_share_variance|
      if cost_share_variance.hios_plan_and_variant_id.split("-").last != "00"
        if cost_share_variance.plan_marketing_name[-2..-1] != "RE" # dont import plans ending with RE (Religious Exemption)
          csr_variant_id = parse_metal_level == "dental" ? "" : /#{cost_share_variance.hios_plan_and_variant_id.split('-').last}/
          plan = Plan.where(active_year: @plan_year,
            hios_id: /#{@qhp.standard_component_id.strip}/,
            hios_base_id: /#{cost_share_variance.hios_plan_and_variant_id.split('-').first}/,
            csr_variant_id: csr_variant_id).to_a.first
          if plan.present?
            plan.update_attributes(name: cost_share_variance.plan_marketing_name.squish!)
          else
            issuer_id = cost_share_variance.hios_plan_and_variant_id[0..4]
            carrier_profile = CarrierProfile.for_issuer_hios_id(issuer_id).first
            carrier_profile_id = carrier_profile.nil? ? nil : carrier_profile.id
            new_plan = Plan.new(
              name: cost_share_variance.plan_marketing_name.squish!,
              hios_id: cost_share_variance.hios_plan_and_variant_id,
              hios_base_id: cost_share_variance.hios_plan_and_variant_id.split("-").first,
              csr_variant_id: cost_share_variance.hios_plan_and_variant_id.split("-").last,
              active_year: @plan_year,
              metal_level: parse_metal_level,
              market: parse_market,
              ehb: @qhp.ehb_percent_premium,
              carrier_profile_id: carrier_profile_id,
              coverage_kind: @qhp.dental_plan_only_ind.downcase == "no" ? "health" : "dental",
              dental_level: @dental_metal_level,
              service_area_id: "DCS001"
              )
            if new_plan.valid?
              new_plan.save!
            else
              @logger.error "\n Failed to create plan: #{new_plan.name}, \n hios product id: #{new_plan.hios_id}\n Errors: #{new_plan.errors.full_messages}\n ******************** \n"
            end
          end
        end
      end
    end
  end

  def create_product_from_serff_data
    @qhp.qhp_cost_share_variances.each do |cost_share_variance|
      if cost_share_variance.hios_plan_and_variant_id.split("-").last != "00"
        if cost_share_variance.plan_marketing_name[-2..-1] != "RE" # dont import plans ending with RE (Religious Exemption)
          csr_variant_id = parse_metal_level == "dental" ? "" : /#{cost_share_variance.hios_plan_and_variant_id.split('-').last}/
          product = ::BenefitMarkets::Products::Product.where(
            hios_id: /#{@qhp.standard_component_id.strip}/,
            hios_base_id: /#{cost_share_variance.hios_plan_and_variant_id.split('-').first}/,
            csr_variant_id: csr_variant_id).select{|a| a.active_year == @plan_year}.first
          if product.present?
            product.update_attributes(title: cost_share_variance.plan_marketing_name.squish!)
          else
            shared_attributes ={
              benefit_market_kind: "aca_#{parse_market}",
              title: cost_share_variance.plan_marketing_name.squish!,
              issuer_profile_id: get_issuer_profile_id,
              hios_id: cost_share_variance.hios_plan_and_variant_id,
              hios_base_id: cost_share_variance.hios_plan_and_variant_id.split("-").first,
              csr_variant_id: cost_share_variance.hios_plan_and_variant_id.split("-").last,
              application_period: (Date.new(@plan_year, 1, 1)..Date.new(@plan_year, 12, 31)),
              service_area_id: mapped_service_area_id,
              # sbc_document: plan.sbc_document, # pending
              deductible: cost_share_variance.qhp_deductable.in_network_tier_1_individual,
              family_deductible: cost_share_variance.qhp_deductable.in_network_tier_1_family,
              is_reference_plan_eligible: true,
            }
            if is_health_product?
              new_product = BenefitMarkets::Products::HealthProducts::HealthProduct.new({
                health_plan_kind: @qhp.plan_type.downcase,
                metal_level_kind: parse_metal_level.to_sym,
                ehb: set_ehb,
              }.merge(shared_attributes))
            else
              new_product = ::BenefitMarkets::Products::DentalProducts::DentalProduct.new({
                product_package_kinds: ::BenefitMarkets::Products::DentalProducts::DentalProduct::PRODUCT_PACKAGE_KINDS
              }.merge(shared_attributes))
            end
            if new_product.valid?
              new_product.save!
            else
              @logger.error "\n Failed to create product: #{new_product.title}, \n hios product id: #{new_product.hios_id}\n Errors: #{new_product.errors.full_messages}\n ******************** \n"
            end
          end
        end
      end
    end
  end

  def set_ehb
    @qhp.ehb_percent_premium.present? ? @qhp.ehb_percent_premium : 1.0
  end

  def get_issuer_profile_id
    @issuer_profile_hash[@qhp.standard_component_id[0..4]]
  end

  def set_issuer_profile_hash
    exempt_organizations = ::BenefitSponsors::Organizations::Organization.issuer_profiles
    exempt_organizations.each do |exempt_organization|
      issuer_profile = exempt_organization.issuer_profile
      issuer_profile.issuer_hios_ids.join.split(",").each do |issuer_hios_id|
        @issuer_profile_hash[issuer_hios_id] = issuer_profile.id.to_s
      end
    end
    @issuer_profile_hash
  end

  def mapped_service_area_id
    @service_area_map[[get_issuer_profile_id.to_s,@qhp.service_area_id,@qhp.active_year]]
  end

  def set_service_areas
    ::BenefitMarkets::Locations::ServiceArea.all.map do |sa|
      @service_area_map[[sa.issuer_profile_id.to_s,sa.issuer_provided_code,sa.active_year]] = sa.id
    end
  end

  def is_health_product?
    @qhp.dental_plan_only_ind.downcase == "no"
  end

  def parse_metal_level
    return "expanded_bronze" if @qhp.metal_level.downcase == "expanded bronze"
    return @qhp.metal_level.downcase unless ["high","low"].include?(@qhp.metal_level.downcase)
    @qhp.metal_level = "dental"
  end

  def parse_market
    @qhp.market_coverage = @qhp.market_coverage.downcase.include?("shop") ? "shop" : "individual"
  end

  def get_carrier_id(name)
    CarrierProfile.find_by_legal_name(name)
  end

  def build_qhp
    @qhp = Products::Qhp.where(active_year: qhp_params[:active_year], standard_component_id: qhp_params[:standard_component_id]).first
    if @qhp.present?
      @qhp.attributes = qhp_params
      @qhp.qhp_benefits = []
      @qhp.qhp_cost_share_variances = []
    else
      @qhp = Products::Qhp.new(qhp_params)
    end
  end

  def build_benefits
    benefits_params.each { |benefit| @qhp.qhp_benefits.build(benefit) }
  end

  def build_cost_share_variances_list
    cost_share_variance_list_params.each do |csvp|
      @csvp = csvp
      next if hios_plan_and_variant_id.split("-").last == "00"
      update_hsa_eligibility
      build_cost_share_variance
    end
  end

  def update_hsa_eligibility
    if hios_plan_and_variant_id.split("-").last == "01" && @qhp.active_year > 2015
      @qhp.hsa_eligibility = hsa_params[:hsa_eligibility]
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

  def hios_plan_and_variant_id
    cost_share_variance_attributes[:hios_plan_and_variant_id]
  end

  def hsa_params
    @csvp[:hsa_attributes]
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
