# frozen_string_literal: true

module FinancialAssistance
  # The ApplicationPolicy class defines the policy for accessing financial assistance applications.
  # It provides methods to check if a user has the necessary permissions to perform various actions on an application.
  class ApplicationPolicy < ::ApplicationPolicy

    def application_family
      @application_family ||= record.family
    end

    def new?; end

    def create?; end

    def edit?
      return true if individual_market_primary_family_member?(application_family)
      return true if active_associated_individual_market_family_broker?(application_family)
      return true if individual_market_admin?

      false
    end

    def index?; end

    def step?
      edit?
    end

    def copy?
      edit?
    end

    def help_paying_coverage?
      edit?
    end

    def application_year_selection?
      edit?
    end

    def application_checklist?
      edit?
    end

    def review_and_submit?
      edit?
    end

    def review?
      edit?
    end

    def wait_for_eligibility_response?
      edit?
    end

    def eligibility_results?
      edit?
    end

    def application_publish_error?
      edit?
    end

    def eligibility_response_error?
      edit?
    end

    def check_eligibility_results_received?
      edit?
    end

    def checklist_pdf?
      edit?
    end

    def update_transfer_requested?
      edit?
    end

    def update_application_year?
      edit?
    end
  end
end
