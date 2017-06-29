module Insured::FamilyMembersHelper
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

  def get_address_from_dependent(dependent)
    if dependent.class == FamilyMember
      dependent.person.addresses
    else
      dependent.family_member.person.addresses
    end
  rescue
    []
  end

  # Returns [url, disable_flag]
  def build_button consumer_role, family, find_sep_url
    if family.application_in_progress.present?
      if family.application_in_progress.ready_for_attestation?
        [review_and_submit_financial_assistance_applications_path, false]
      else
        [review_and_submit_financial_assistance_applications_path, true]
      end
    else
      [(consumer_role.present? && !is_under_open_enrollment? ? find_sep_url : group_selection_url), false]
    end
  end

  def find_applicant family_member
    if family_member.class == Forms::FamilyMember
      # AJAX add of family member
      #family_member dutring ajax call is a Form::FamilyMemeber which has a FamilyMember
      family_member.family_member.applicant
    else
      family_member.applicant
    end
  end
end
