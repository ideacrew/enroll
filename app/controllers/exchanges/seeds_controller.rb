# frozen_string_literal: true

module Exchanges
  # Controller where HBX Admins can upload CSV templates for seeding
  # data with Golden Seed. Seeds will be performed asyncronously
  class SeedsController < ApplicationController
    include ::DataTablesAdapter #TODO: check
    include ::Pundit

  # layout 'single_column'
    layout 'bootstrap_4'
    before_action :set_seed, only: %i[edit]
    before_action :csv_format_valid?, only: %i[create]

    before_action :redirect_if_prod, :check_hbx_staff_role
    def new
      @seed = Seeds::Seed.new(user: current_user)
    end

    # need to validate CSV template
    def create
      @seed = Seeds::Seed.new(
        user: current_user,
        filename: params[:file].send(:original_filename), # Get filename
        csv_template: params[:csv_template],
        aasm_state: 'draft'
      )

      if params[:file].present? && !valid_file_upload?(params[:file], FileUploadValidator::CSV_TYPES)
        redirect_to exchanges_seeds_path
        return
      end
      # TODO: need to figure out how to save the file
      CSV.foreach(params[:file].send(:tempfile), headers: true) do |csv_row|
        # Conversion for CSV is weird
        row_data_hash = {}
        row_keys = csv_row.to_h.keys
        row_keys.each do |row_key|
          row_data_hash[row_key] = csv_row[row_key]
        end
        @seed.rows.build(data: row_data_hash.with_indifferent_access)
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
          flash.now[:notice] = l10n("seeds_ui.begin_seed_message")
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

    # TODO: Refactor this
    # rubocop:disable Metrics/CyclomaticComplexity
    def csv_format_valid?
      if params[:file].blank?
        # TODO: refactoor as translation
        flash[:error] = "Please add a CSV file."
        @seed = Seeds::Seed.new(user: current_user)
        render 'new' and return
      end
      unless params[:file].send(:content_type) == 'text/csv'
        # TODO: Refactor as translation
        flash.now[:error] = "Unable to use CSV template. Must be in CSV format."
        @seed = Seeds::Seed.new(user: current_user)
        render 'new' and return
      end
      uploaded_csv_headers = CSV.read(params[:file].send(:tempfile), return_headers: true)&.first&.compact
      if uploaded_csv_headers.blank?
        # TODO: Refactor as translation
        flash.now[:error] = "No headers detected in CSV."
        @seed = Seeds::Seed.new(user: current_user)
        render 'new' and return
      end
      # they need to choose a template on the new form, and then make sure that matches one that way.
      # Also need to add model validations.
      chosen_template_headers = Seeds::Seed::REQUIRED_CSV_HEADER_TEMPLATES[params[:csv_template].to_sym]
      # Same exact headers
      # After ruby 2.6 +, get rid of the set and just use it as array methods
      # https://stackoverflow.com/a/56739603/5331859
      incorrect_headers = []
      uploaded_csv_headers.each do |uploaded_csv_header|
        incorrect_headers << uploaded_csv_header if chosen_template_headers.exclude?(uploaded_csv_header)
      end
      return unless incorrect_headers.present?
      # TODO: Refactor as translation
      error_message = "CSV does not match #{params[:csv_template]} template. Must use headers (in any order) #{chosen_template_headers}. "\
      "Remove unnecessary headers #{incorrect_headers}"
      flash.now[:error] = error_message
      @seed = Seeds::Seed.new(user: current_user)
      render 'new' and return
    end
    # rubocop:enable Metrics/CyclomaticComplexity

    def set_seed
      @seed = Seeds::Seed.find(params[:id])
    end
  end
end
