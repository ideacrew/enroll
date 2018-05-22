class VueController < ApplicationController
  before_action :set_translation, only: [:show, :edit, :update, :destroy]

  layout "simple"

  def my_sample
    render 'hello'
  end

  def index

  end

  def calc
    @employer_profile = EmployerProfile.find(params[:employer_profile_id])
    @benefit_group_index = params[:benefit_group_index].to_i
    params.merge!({ plan_year: { start_on: params[:start_on] }.merge(relationship_benefits) })
    @coverage_type = params[:coverage_type]
    @plan = Plan.find(params[:reference_plan_id])
    @plan_year = ::Forms::PlanYearForm.build(@employer_profile, plan_year_params)
    if @coverage_type == '.dental'
      @plan_year.benefit_groups[0].dental_reference_plan = @plan
      coverage_type = 'dental'
    else
      @plan_year.benefit_groups[0].reference_plan = @plan
    end

    @employer_contribution_amount = @plan_year.benefit_groups[0].monthly_employer_contribution_amount(@plan)
    @min_employee_cost = @plan_year.benefit_groups[0].monthly_min_employee_cost(coverage_type)
    @max_employee_cost = @plan_year.benefit_groups[0].monthly_max_employee_cost(coverage_type)


    render json: {:ok => 1, :employer_amount => @employer_contribution_amount, :min_employee_cost => @min_employee_cost, :max_employee_cost => @max_employee_cost}
  end

  def carriers
    carriers = []
    Organization.exists(carrier_profile: true).each do |c|
      carriers << {:carrier => {:name => c.legal_name, :id => c.carrier_profile.id, :image => "/logo/carrier/" + c.legal_name.downcase.parameterize.underscore + ".jpg" } }
    end
    render json: carriers.to_json
  end

  def save
    render json: {:ok => 1}
  end

  def plans
    my_plans = []
    #Plan.valid_shop_by_metal_level_and_year("gold",2018).limit(25).each do |p|
    Plan.where("active_year" => 2018).limit(25).each do |p|
      my_plans << { :image_url => "/logo/carrier/" + p.carrier_profile.legal_name.downcase.parameterize.underscore + ".jpg",
                    :carrier_name => p.carrier_profile.legal_name,
                    :nationwide => p.nationwide ? "Yes" : "No", :render_class => false, :id => p.id, :plan => p.attributes[:name], :metal_level => p.metal_level.capitalize, :market => p.market, :active_year => p.active_year
      }
    end
    render json: my_plans.to_json
  end

  def employers
    data = []
    Organization.all_employer_profiles.each do |e|
      data << {:id => e.employer_profile.id, :legal_name => e.legal_name}
    end
    render json: data.to_json
  end

  def load_plans
    my_plans = []
    Plan.by_carrier_profile(params[:vue_id]).each do |p|
      my_plans << {:plan => p.name, :carrier_name => p.carrier_profile.legal_name, :metal_level => p.metal_level, :market => p.market, :active_year => p.active_year}
    end
    render json: my_plans.to_json
  end

  def plan_year_params
    plan_year_params = params.require(:plan_year).permit(
      :start_on, :end_on, :fte_count, :pte_count, :msp_count,
      :open_enrollment_start_on, :open_enrollment_end_on,
      :benefit_groups_attributes => [ :id, :title, :description, :reference_plan_id, :dental_reference_plan_id, :effective_on_offset,
                                      :carrier_for_elected_plan, :carrier_for_elected_dental_plan, :metal_level_for_elected_plan,
                                      :plan_option_kind, :dental_plan_option_kind, :employer_max_amt_in_cents, :_destroy, :dental_relationship_benefits_attributes_time,
                                      :relationship_benefits_attributes => [
                                        :id, :relationship, :premium_pct, :employer_max_amt, :offered, :_destroy
                                      ],
                                      :dental_relationship_benefits_attributes => [
                                        :id, :relationship, :premium_pct, :employer_max_amt, :offered, :_destroy
                                      ]
    ]
    )

    plan_year_params["benefit_groups_attributes"].delete_if {|k, v| v.count < 2 }
    plan_year_params
  end

  def relationship_benefits
    {
      "benefit_groups_attributes" =>
      {
        "0" => {
           "title"=>"Place Holder",
           # "carrier_for_elected_plan"=>"53e67210eb899a4603000004",
           "reference_plan_id" => params[:reference_plan_id],
           "relationship_benefits_attributes" => params[:relation_benefits],
           "dental_relationship_benefits_attributes" => params[:dental_relation_benefits]
        }
      }
    }
  end

end
