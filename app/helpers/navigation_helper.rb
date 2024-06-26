# frozen_string_literal: true

module NavigationHelper
  def tell_us_about_yourself_active?
    return true if controller_name == "consumer_roles" && ['edit', 'ridp_agreement'].include?(action_name)
    return true if controller_name == "interactive_identity_verifications"
    return true if ["help_paying_coverage", "application_checklist", "application_year_selection"].include?(action_name)
    return true if controller_name == "family_members" && action_name == "index"
    return true if controller_name == "family_relationships" && action_name == "index"
  end

  def account_registration_active?
    ["search", "match"].include?(action_name)
  end

  def tell_us_about_yourself_current_step?
    return true if controller_name == "consumer_roles" && ['edit', 'ridp_agreement'].include?(action_name)
    return true if controller_name == "interactive_identity_verifications"
    return true if ["help_paying_coverage", "application_checklist", "application_year_selection"].include?(action_name)
  end

  def family_members_index_active?
    return true if controller_name == "family_members" && action_name == "index"
    return true if controller_name == "family_relationships" && action_name == "index"
  end

  def family_members_index_current_step?
    return true if controller_name == "family_relationships" && action_name == "index"
    return true if controller_name == "family_members" && action_name == "index"
  end

  def local_assigned_boolean(local, default)
    return default unless local
    local == "true"
  end

  def special_enrollment_period_hash
    if @change_plan.blank?
      sep_nav_options
    else
      sep_shop_for_plans_nav_options
    end
  end

  def family_info_progress_hash
    if @change_plan.present?
      qle_nav_options
    elsif @type == "employee"
      sep_nav_options
    else
      individual_nav_options
    end
  end

  def plan_shopping_progress_hash
    if @change_plan.blank? && @market_kind == "individual"
      if @enrollment_kind.blank? && is_under_open_enrollment?
        individual_nav_options
      else
        sep_nav_options
      end
    elsif @change_plan == "change_by_qle"
      qle_nav_options
    elsif @change_plan == "change_plan"
      if (@market_kind == "individual" && !is_under_open_enrollment?) || @enrollment_kind == 'sep'
        sep_shop_for_plans_nav_options
      else
        shop_for_plans_nav_options
      end
    end
  end

  def sign_up_nav_options
    [
      {step: 1, page_key: :personal_info, display_label: l10n('tell_us_about_yourself')},
      {step: 2, page_key: :family_info, display_label: l10n('family_info')}
    ]
  end

  def individual_nav_options
    [
      {step: 1, page_key: :personal_info, display_label: l10n('personal_information')},
      {step: 2, page_key: :verify_identity, display_label: l10n('insured.consumer_roles.upload_ridp_documents.header')},
      {step: 3, page_key: :household_info, display_label: l10n('household_info')},
      {step: 4, page_key: :choose_plan, display_label: l10n('choose_plan')},
      {step: 5, page_key: :review, display_label: l10n('confirm_selection')},
      {step: 6, page_key: :complete, display_label: l10n('complete')}
    ]
  end

  def sep_nav_options
    [
      {step: 1, page_key: :personal_info, display_label: l10n('personal_information')},
      {step: 2, page_key: :verify_identity, display_label: l10n('verify_identity')},
      {step: 3, page_key: :household_info, display_label: l10n('household_info')},
      {step: 4, page_key: :sep, display_label: l10n('insured.families.special_enrollment_period')},
      {step: 5, page_key: :choose_plan, display_label: l10n('choose_plan')},
      {step: 6, page_key: :review, display_label: l10n('confirm_selection')},
      {step: 7, page_key: :complete, display_label: l10n('complete')}
    ]
  end

  def qle_nav_options
    [
      {step: 1, page_key: :household_info, display_label: l10n('household_info')},
      {step: 2, page_key: :choose_plan, display_label: l10n('plan_selection')},
      {step: 3, page_key: :review, display_label: l10n('review')},
      {step: 4, page_key: :complete, display_label: l10n('complete')}
    ]
  end

  def sep_shop_for_plans_nav_options
    [
      {step: 1, page_key: :sep, display_label: l10n('insured.families.special_enrollment_period')},
      {step: 2, page_key: :choose_plan, display_label: l10n('plan_selection')},
      {step: 3, page_key: :review, display_label: l10n('review')},
      {step: 4, page_key: :complete, display_label: l10n('complete')}
    ]
  end

  def shop_for_plans_nav_options
    [
      {step: 1, page_key: :choose_plan, display_label: l10n('plan_selection')},
      {step: 2, page_key: :review, display_label: l10n('review')},
      {step: 3, page_key: :complete, display_label: l10n('complete')}
    ]
  end
end
