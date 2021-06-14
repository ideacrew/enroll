# frozen_string_literal: true

module Exchanges
  # Controller where HBX Admins can upload CSV templates for seeding
  # data with Golden Seed. Seeds will be performed asyncronously
  class SeedsController < ApplicationController
    include ::DataTablesAdapter #TODO: check
    include ::Pundit
    include ::L10nHelper

  # layout 'single_column'
    layout 'bootstrap_4'
    before_action :set_seed, only: %i[edit]

    # before_action :only_preprod, :check_hbx_staff_role
    def new
      @seed = Seeds::Seed.new(user: current_user)
    end

    # need to validate CSV template
    def create
      @seed = Seeds::Seed.new(
        user: current_user,
        filename: params[:file], # Get filename
        aasm_state: 'draft'
      )
      # TODO: need to figure out how to save the file
      CSV.foreach(params[:file], headers: true) do |row|
        # To avoid nil values
        row_data = row.to_h.reject { |key, _value| key.blank? }.transform_values { |v| v.blank? ? "" : v }.with_indifferent_access
        @seed.rows.build(data: row_data)
        @seed.rows.build(data: row_data)
      end
      if @seed.save
        redirect_to(
          edit_exchanges_seed_path(@seed.id),
          flash: {success: l10n("seeds_ui.seed_created_message")}
        )
      else
        render 'new'
      end
    end

    # Need to figure out what to do here
    # And add actions and whatnot
    def index
      @seeds = Seeds::Seed.all
    end

    # Kicks of the seed process
    def update
      @seed = Seeds::Seed.find(params[:id])
      @seed.process! if params[:commit].downcase == 'begin seed'
      flash[:notice] = l10n("seeds_ui.begin_seed_message")
      render 'edit'
    end

    # TODO: Make strong params
    # def csv_params; end
    private

    def set_seed
      @seed = Seeds::Seed.find(params[:id])
    end
  end
end
