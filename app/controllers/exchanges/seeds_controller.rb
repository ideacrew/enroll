class Exchanges::SeedsController < ApplicationController
  include ::DataTablesAdapter #TODO: check
  include ::Pundit
  include ::L10nHelper

  # layout 'single_column'
  layout 'bootstrap_4'

  # before_action :only_preprod, :check_hbx_staff_role
  def new
    @seed = Seeds::Seed.new(user: current_user)
  end
  
  # need to validate CSV template
  def create
    @seed = Seeds::Seed.new(
      user: current_user,
      filename: params[:file] # Get filename
    )
    CSV.foreach(params[:file]) do |row|
      @seed.rows.build(data: row.to_h)
    end
    if @seed.save
      redirect_to exchanges_seeds_edit_path(@seed)
    else
      render 'new'
    end
  end

  # Kicks of the seed process
  def update
    @seed = Seeds::Seed.find(params[:id])
    if params[:commit].downcase == 'seed'
      @seed.process!
    end
    render 'edit'
  end

  # TODO: Make strong params
  # def csv_params; end
end
