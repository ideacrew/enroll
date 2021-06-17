# frozen_string_literal: true

module Exchanges
  # Controller where HBX Admins can upload CSV templates for seeding
  # data with Golden Seed. Seeds will be performed asyncronously
  class SeedsController < ApplicationController
    include ::DataTablesAdapter #TODO: check
    include ::Pundit
    include ActionView::Helpers::TranslationHelper
    include L10nHelper

  # layout 'single_column'
    layout 'bootstrap_4'
    before_action :set_seed, only: %i[edit]
    before_action :csv_format_valid?, only: %i[create]

    before_action :nonprod_environment?, :check_hbx_staff_role
    def new
      @seed = Seeds::Seed.new(user: current_user)
    end

    # need to validate CSV template
    def create
      @seed = Seeds::Seed.new(
        user: current_user,
        filename: params[:file].send(:original_filename), # Get filename
        csv_template: @csv_template,
        aasm_state: 'draft'
      )
      # TODO: need to figure out how to save the file
      CSV.foreach(params[:file].send(:tempfile), headers: true) do |row|
        # To avoid nil values
        # TODO: Make sure case notese is gooing through
        row_data = row.to_h.reject { |key, _value| key.blank? }.transform_values { |v| v.blank? ? "" : v }.with_indifferent_access
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
      respond_to do |format|
        format.html do
          flash[:notice] = l10n("seeds_ui.begin_seed_message")
          render 'edit'
        end
        format.js { head :ok }
      end
    end

    # TODO: Need to add the template for them to download on index. Not sure if it should be here.
    # def download_csv_template; end

    # TODO: Make strong params
    # def csv_params; end

    private

    def check_hbx_staff_role
      redirect_to root_path, :flash => { :error => "You must be an HBX staff member" } unless current_user.has_hbx_staff_role?
    end

    def csv_format_valid?
      unless params[:file].send(:content_type) == 'text/csv'
        # TODO: Refactor as translation
        flash[:error] = "Unable to use CSV template. Must be in CSV format."
        render 'new' and return
      end
      uploaded_csv_headers = CSV.read(params[:file].send(:tempfile), return_headers: true).first.compact
      header_difference = nil
      Seeds::Seed::REQUIRED_CSV_HEADER_TEMPLATES.each do |template_name, csv_headers|
        # Same exact headers
        # After ruby 2.6 +, get rid of the set and just use it as array methods
        # https://stackoverflow.com/a/56739603/5331859
        header_difference = csv_headers.uniq.sort.to_set.difference(uploaded_csv_headers.uniq.sort.to_set)
        if header_difference.blank?
          @csv_template = template_name.to_s
          break
        end
      end
      return unless header_difference.present?
      # TODO: Refactor as translation
      flash[:error] = "Unable to use CSV template. Contains incorrect header values: #{header_difference.to_a}."
      render 'new' and return
    end

    def set_seed
      @seed = Seeds::Seed.find(params[:id])
    end
  end
end
