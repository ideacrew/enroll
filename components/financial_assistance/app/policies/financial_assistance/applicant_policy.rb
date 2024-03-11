# frozen_string_literal: true

module FinancialAssistance
  class ApplicantPolicy < ::ApplicationPolicy

    def initialize(user, record)
      super
      @family ||= record.application.family
    end

    def new?; end

    def create?; end

    def edit?
      return true if individual_market_primary_family_member?
      return true if active_associated_individual_market_ridp_verified_family_broker?
      return true if individual_market_admin?

      false
    end

    def update?
      edit?
    end

    def other_questions?
      edit?
    end

    def save_questions?
      edit?
    end

    def step?
      edit?
    end

    def age_of_applicant?
      edit?
    end

    def applicant_is_eligible_for_joint_filing?
      edit?
    end

    def immigration_document_options?
      edit?
    end

    def destroy?
      edit?
    end
  end
end
