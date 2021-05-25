# frozen_string_literal: true

module MagiMedicaid
  #magi medicaid application helper.
  module ApplicationHelper
    def show_faa_status
      return true if controller_name == 'applications' && action_name == 'edit'
      false
    end
  end
end
