class QhpBuilder
  LOG_PATH = "#{Rails.root}/log/rake_xml_import_plans_#{Time.now.to_s.gsub(' ', '')}.log"
  LOGGER = Logger.new(LOG_PATH)

  def initialize(qhp_hash)
    @qhp_hash = qhp_hash
    @qhp_array = qhp_hash[:packages_list][:packages]
  end

  def run
    @xml_plan_counter, @success_plan_counter = 0,0
    iterate_plans
    show_qhp_stats
  end

  def iterate_plans
    @qhp_array.each do |plans|
      @plans = plans
      @xml_plan_counter += plans[:plans_list][:plans].size
      plans[:plans_list][:plans].each do |plan|
        @plan = plan
        build_qhp_params
      end
    end
  end

  def build_qhp_params
    build_qhp
    build_benefits
    build_cost_share_variance
    build_moops
    build_service_visits
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
      @qhp.save!
      @success_plan_counter += 1
      LOGGER.info "\nSaved Plan: #{@qhp.plan_marketing_name}, hios product id: #{@qhp.hios_product_id} \n"
    rescue Exception => e
      LOGGER.error "\n Failed to create plan: #{@qhp.plan_marketing_name}, \n hios product id: #{@qhp.hios_product_id} \n Exception Message: #{e.message} \n\n Errors: #{@qhp.errors.full_messages} \n ******************** \n"
    end
  end

  def build_qhp
    @qhp = Products::Qhp.new(qhp_params)
  end

  def build_benefits
    benefits_params.each { |benefit| @qhp.qhp_benefits.build(benefit) }
  end

  def build_cost_share_variance
    @qhp.build_qhp_cost_share_variance.attributes = cost_share_variance_params
    @qhp.qhp_cost_share_variance.build_qhp_deductable.attributes = deductible_params
  end

  def build_moops
    maximum_out_of_pockets_params.each { |moop| @qhp.qhp_cost_share_variance.qhp_maximum_out_of_pockets.build(moop) }
  end

  def build_service_visits
    service_visits_params.each { |visits| @qhp.qhp_cost_share_variance.qhp_service_visits.build(visits) }
  end

  def cost_share_variance_params
    cost_share_variance_list_params[:cost_share_variance_attributes].merge(sbc_params)
  end

  def service_visits_params
    cost_share_variance_list_params[:service_visits_attributes]
  end

  def deductible_params
    cost_share_variance_list_params[:deductible_attributes]
  end

  def maximum_out_of_pockets_params
    cost_share_variance_list_params[:maximum_out_of_pockets_attributes]
  end

  def sbc_params
    cost_share_variance_list_params[:sbc_attributes]
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
    @plan[:plan_attributes]
  end

end