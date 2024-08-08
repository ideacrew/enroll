# frozen_string_literal: true

module Exchanges
  class TimeKeeperController < ApplicationController
    include EventSource::Command

    def hop_to_date
      authorize HbxProfile, :modify_admin_tabs? # Rename this to something more meaningful for this action
      new_date = Date.parse(params[:forms_time_keeper][:date_of_record])

      if new_date > Date.today && new_date > TimeKeeper.date_of_record
        TimeKeeper.instance.set_date_of_record(date)
        flash[:notice] = "Time Hop is successful, Date is advanced to #{TimeKeeper.date_of_record.strftime('%m/%d/%Y')}"
      else
        flash[:error] = "Invalid date, please select a future date"
      end

      redirect_to configuration_exchanges_hbx_profiles_path
    rescue StandardError => e
      flash[:error] = e.message
    end
  end
end