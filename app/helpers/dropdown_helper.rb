# frozen_string_literal: true

# Helper for constructing dropdown options for use in the `datatables/shared/_dropdown` partial
module DropdownHelper
  def application_dropdowns(application)
    construct_options(:construct_static_option, [
      (['faa.applications.actions.update', edit_application_path(application)] if application.is_draft? || (application.imported? && current_user.has_hbx_staff_role?)),
      (['faa.applications.actions.copy', copy_application_path(application)] unless do_not_allow_copy?(application, current_user)),
      (['faa.applications.actions.view_eligibility', eligibility_results_application_path(application)] if application.is_determined? || application.is_terminated?),
      (['faa.applications.actions.review', review_application_path(application)] if application.is_reviewable?),
      (['faa.applications.actions.full_application', raw_application_application_path(application)] if current_user.has_hbx_staff_role? && application.is_reviewable?),
      (['faa.applications.actions.transfer_history', transfer_history_application_path(application)] if current_user.has_hbx_staff_role? && FinancialAssistanceRegistry.feature_enabled?(:transfer_history_page))
    ])
  end

  private

  DEFAULT = {data: {turbolinks: false}}.freeze

  def construct_options(options_mapper, options_args)
    options_args.compact.map { |args| method(options_mapper).call(*args) }
  end

  def construct_option(title_key, link, attributes)
    {title: l10n(title_key), link: link, attributes: attributes}
  end

  def construct_static_option(title_key, link)
    construct_option(title_key, link, DropdownHelper::DEFAULT.dup)
  end
end