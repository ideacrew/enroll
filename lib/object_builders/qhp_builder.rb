class QhpBuilder

  def initialize(qhp_hash)
    @qhp_array = qhp_hash[:packages_list][:packages]
  end

  def build_and_save
    @qhp_array.each do |hash_attributes|
      @hash_attributes = hash_attributes

      @qhp = Products::Qhp.new(qhp_params)

      # Benefits
      benefits_params.each do |benefit|
        @qhp.qhp_benefits.build(benefit)
      end

      # Cost Share Variance
      @qhp.build_qhp_cost_share_variance.attributes = cost_share_variance_params
      @qhp.qhp_cost_share_variance.build_qhp_deductable.attributes = deductible_params

      maximum_out_of_pockets_params.each do |moop|
        @qhp.qhp_cost_share_variance.qhp_maximum_out_of_pockets.build(moop)
      end

      service_visits_params.each do |visits|
        @qhp.qhp_cost_share_variance.qhp_service_visits.build(visits)
      end

      @qhp.save
    end
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
    plans_params[:cost_share_variance_list_attributes]
  end

  def benefits_params
    @hash_attributes[:benefits_list][:benefits]
  end

  def qhp_params
    header_params.merge(plan_attribute_params)
  end

  def header_params
    @hash_attributes[:header]
  end

  def plans_params
    @hash_attributes[:plans_list][:plans].first
  end

  def plan_attribute_params
    plans_params[:plan_attributes]
  end

end