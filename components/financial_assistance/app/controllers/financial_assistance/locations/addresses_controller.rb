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
      # @return [FinancialAssistance::Locations::Address, ActionDispatch::Response] The address to be destroyed, or redirects back to the previous page if not found.
      def fetch_address
        @application = ::FinancialAssistance::Application.where(id: destroy_params[:application_id]).first
        unless @application
          flash[:error] = 'Application not found with the given parameters.'
          return redirect_back(fallback_location: main_app.root_path)
        end

        @applicant = @application.applicants.where(id: destroy_params[:applicant_id]).first
        unless @applicant
          flash[:error] = 'Applicant not found with the given parameters.'
          return redirect_back(fallback_location: main_app.root_path)
        end

        @address = @applicant.addresses.where(id: destroy_params[:id]).first

        return if @address

        flash[:error] = 'Address not found with the given parameters.'
        redirect_back(fallback_location: main_app.root_path)
      end
    end
  end
end
