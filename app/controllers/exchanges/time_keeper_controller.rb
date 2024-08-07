# frozen_string_literal: true

module Exchanges
  class TimeKeeperController < ApplicationController
    include EventSource::Command

    def hop_to_date
      binding.irb
      authorize HbxProfile, :modify_admin_tabs? # Rename this to something more meaningful for this action
      binding.irb
      date = Date.parse(params[:forms_time_keeper][:date_of_record])
      binding.irb
      TimeKeeper.instance.set_date_of_record(date)
      flash[:notice] = "Time Hop to #{TimeKeeper.date_of_record.strftime('%m/%d/%Y')}"

      redirect_to configuration_exchanges_hbx_profiles_path
    end

  end
end