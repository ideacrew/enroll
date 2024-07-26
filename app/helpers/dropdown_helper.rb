# frozen_string_literal: true

# Helper for constructing dropdown options for use in the `datatables/shared/_dropdown` partial
module DropdownHelper
  def application_dropdowns(application)
    option_args = [
      (['faa.applications.actions.update', edit_application_path(application), :default] if application.is_draft? || (application.imported? && current_user.has_hbx_staff_role?)),
      (['faa.applications.actions.copy', copy_application_path(application), :default] unless do_not_allow_copy?(application, current_user)),
      (['faa.applications.actions.view_eligibility', eligibility_results_application_path(application), :default] if application.is_determined? || application.is_terminated?),
      (['faa.applications.actions.review', review_application_path(application), :default] if application.is_reviewable?)
    ]
    option_args = add_hbx_only_dropdowns(application, option_args)
    construct_options(option_args)
  end

  private

  # dropdown type link attributes
  DEFAULT = {data: {turbolinks: false}}.freeze

  def construct_options(options_args)
    options_args.compact.map { |option_args| construct_option(*option_args) }
  end

  def construct_option(title_key, link, option_type)
    {title: l10n(title_key), link: link, attributes: attribute_hash(option_type)}
  end

  def attribute_hash(option_type)
    case option_type
    when :default
      ::DropdownHelper::DEFAULT.dup
    end
  end

  def add_hbx_only_dropdowns(application, options)
    return options unless current_user.has_hbx_staff_role?
    options << (['faa.applications.actions.transfer_history', transfer_history_application_path(application), :default] if FinancialAssistanceRegistry.feature_enabled?(:transfer_history_page))
    options << (['faa.applications.actions.full_application', raw_application_application_path(application), :default] if current_user.has_hbx_staff_role? && application.is_reviewable?)
  end
end
