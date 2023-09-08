# frozen_string_literal: true

# copy of app/helpers/insured
module Insured
  # copy of app/helpers/insured/family_members_helper.rb
  module FamilyMembersHelper
    def employee_dependent_form_id(model)
      if model.try(:persisted?)
        "add_member_list_#{model.id}"
      else
        "new_employee_dependent_form"
      end
    end

    def employee_dependent_submission_options_for(model)
      if model.try(:persisted?)
        { :remote => true, method: :put, :url => insured_family_member_path(id: model.id), :as => :dependent }
      else
        { :remote => true, method: :post, :url => insured_family_members_path, :as => :dependent }
      end
    end

    # rubocop:disable Lint/EmptyRescueClause
    def get_address_from_dependent(dependent)
      if dependent.instance_of?(FamilyMember)
        dependent.person.addresses
      else
        dependent.family_member.person.addresses
      end
    rescue StandardError
      []
    end
    # rubocop:enable Lint/EmptyRescueClause

    def is_applying_coverage_value_dependent(dependent)
      first_checked = true
      second_checked = false
      if dependent.family_member.try(:person).try(:consumer_role).present?
        first_checked = dependent.family_member.person.consumer_role.is_applying_coverage
        second_checked = !dependent.family_member.person.consumer_role.is_applying_coverage
      end
      [first_checked, second_checked]
    end
  end
end
