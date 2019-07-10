# frozen_string_literal: true

module Exchanges
  class IssuersController < ApplicationController
    before_action :check_hbx_staff_role, only: [:index]
    layout 'single_column'

    def index
      issuers = ::BenefitSponsors::Services::IssuerDataTableService.new
      table_data = issuers.retrieve_table_data
      @data = ::BenefitSponsors::Serializers::IssuerDatatableSerializer.new(table_data).serialized_json
      respond_to do |format|
        format.js
        format.json { render json: @data }
      end
    end

    private

    def check_hbx_staff_role
      redirect_to root_path, :flash => { :error => "You must be an HBX staff member" } unless current_user.has_hbx_staff_role?
    end
  end
end