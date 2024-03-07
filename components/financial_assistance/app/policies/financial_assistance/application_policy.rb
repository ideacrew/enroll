# frozen_string_literal: true

module FinancialAssistance
  # This class is base policy class
  # The ApplicationPolicy class is responsible for determining what actions a user can perform on Application records.
  # It checks if the user has the necessary permissions to perform actions on applications.
  # The permissions are determined based on the user's role and their relationship to the record.
  class ApplicationPolicy < Policy

    # TODO: Add policies for all the endpoints of the ApplicationController for Application
    # Call the test method to check if the user has the necessary permissions to perform actions on application(s)

    def test
      # TODO: Find family and call can_transform? method
      can_transform?(family)
    end
  end
end
