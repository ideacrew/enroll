class VueController < ApplicationController
  before_action :set_translation, only: [:show, :edit, :update, :destroy]

  layout "simple"

  def my_sample
    render 'hello'
  end

  def index

  end

  def calc
    binding.pry
    render json: {:ok => 1}
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
      my_plans << {:nationwide => p.nationwide ? "Yes" : "No", :render_class => false, :id => p.id, :plan => p.attributes[:name], :metal_level => p.metal_level.capitalize, :market => p.market, :active_year => p.active_year}
    end
    render json: my_plans.to_json
  end

  def employers
    data = []
    Organization.all_employer_profiles.each do |e|
      data << {:id => e.id, :legal_name => e.legal_name}
    end
    render json: data.to_json
  end

  def load_plans
    my_plans = []
    Plan.by_carrier_profile(params[:vue_id]).each do |p|
      my_plans << {:plan => p.attributes[:name], :metal_level => p.metal_level, :market => p.market, :active_year => p.active_year}
    end
    render json: my_plans.to_json
  end

end
