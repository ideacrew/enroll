# frozen_string_literal: true

module FinancialAssistance
  module Locations
    # AddressesController handles the CRUD operations for addresses.
    class AddressesController < ::FinancialAssistance::ApplicationController

      before_action :fetch_address, only: [:destroy]

      # @todo: Add translations for the flash messages.
      # @todo: Fix the redirection after the operation for both success and failure cases.

      # Deletes an address.
      #
      # DELETE /applications/:application_id/applicants/:applicant_id/locations/addresses/:id(.:format)
      #
      # @return [ActionDispatch::Response] Redirects back to the previous page after the operation.
      def destroy
        authorize @address, :destroy?

        result = ::FinancialAssistance::Operations::Locations::Addresses::Destroy.new.call(@address)

        if result.success?
          flash[:notice] = "Address is successfully destroyed."
        else
          flash[:error] = "Failed to destroy address: #{result.failure}"
        end

        redirect_back(fallback_location: main_app.root_path)
      end

      private

      # Fetches the parameters required to destroy an address.
      #
      # @return [ActionController::Parameters] The permitted parameters.
      def destroy_params
        return @destroy_params if defined? @destroy_params

        @destroy_params = params.permit(:application_id, :applicant_id, :id)
      end

      # Fetches the address to be destroyed.
      #
      # @return [FinancialAssistance::Locations::Address, nil] The address to be destroyed, or nil if not found.
      def fetch_address
        @address = ::FinancialAssistance::Application.find(
          destroy_params[:application_id]
        ).applicants.find(destroy_params[:applicant_id]).addresses.find(destroy_params[:id])
      rescue Mongoid::Errors::DocumentNotFound => e
        Rails.logger.error "Error finding the FinancialAssistance::Locations::Address with params: #{
          destroy_params.to_h} with error message: #{e.message}"

        flash[:error] = 'Address not found with the given parameters.'
        redirect_back(fallback_location: main_app.root_path) and return
      end
    end
  end
end
