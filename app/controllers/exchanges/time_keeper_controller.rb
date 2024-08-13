# frozen_string_literal: true

module Exchanges
  # This controller is responsible for handling the time jump functionality.
  class TimeKeeperController < ApplicationController
    include EventSource::Command

    def hop_to_date
      authorize HbxProfile, :hop_to_date?

      result = Operations::HbxAdmin::TimeJump.new.call({new_date: permit_params.to_h["date_of_record"]})

      if result.success?
        flash[:notice] = result.value!
      else
        flash[:error] = result.failure
      end

      redirect_to configuration_exchanges_hbx_profiles_path
    rescue StandardError => e
      flash[:error] = e.message
    end

    private

    def permit_params
      params.require(:forms_time_keeper).permit(:date_of_record)
    end
  end
end