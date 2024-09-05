# frozen_string_literal: true

# Helper for constructing dropdown options for use in the `datatables/shared/_dropdown` partial
module DropdownHelper
  # the dropdowns used for the Applications index - these live outside of datatable
  def application_dropdowns(application)
    option_args = [
      ([l10n('faa.applications.actions.update'), edit_application_path(application), :default] if application.is_draft? || (application.imported? && current_user.has_hbx_staff_role?)),
      ([l10n('faa.applications.actions.copy'), copy_application_path(application), :default] unless do_not_allow_copy?(application, current_user)),
      ([l10n('faa.applications.actions.view_eligibility'), eligibility_results_application_path(application), :default] if application.is_determined? || application.is_terminated?),
      ([l10n('faa.applications.actions.review'), review_application_path(application), :default] if application.is_reviewable?)
    ]
    option_args = add_hbx_only_dropdowns(application, option_args)
    construct_options(option_args)
  end

  # map legacy dropdowns to BS4 dropdowns
  # NOTE: should remove & refactor dropdowns from callers once BS4 is turned on
  # TODO: maybe move into a new dedicated module Datatables file to be defined solely there and called from the datables
  def datatable_dropdowns(dropdowns)
    return dropdowns unless @bs4
    dropdowns.each { |dropdown| dropdown[2] = dropdown_type(dropdown[2]) }
    dropdowns.select! { |option| option[2].present? } if @bs4 # legacy disabled dropdowns are not rendered on BS4
    construct_options(dropdowns)
  end

  private

  # dropdown type link attributes
  DEFAULT = {data: {turbolinks: false}}.freeze
  REMOTE = {remote: true}.freeze
  REMOTE_EDIT_APTC_CSR = {class: "edit-aptc-csr-enabled", remote: true}.freeze

  def construct_options(options_args)
    options_args.compact.map { |option_args| construct_option(*option_args) }
  end

  def construct_option(title, link, option_type)
    {title: title, link: link, attributes: attribute_hash(option_type)}
  end

  # map dropdown type keys to link attributes
  def attribute_hash(option_type)
    case option_type
    when :default
      ::DropdownHelper::DEFAULT.dup
    when :remote
      ::DropdownHelper::REMOTE.dup
    when :remote_edit_aptc_csr
      ::DropdownHelper::REMOTE_EDIT_APTC_CSR.dup
    end
  end

  # map legacy dropdown types to BS4 dropdown types
  # NOTE: should remove & update dropdown types from callers once BS4 is turned on
  def dropdown_type(legacy_type)
    case legacy_type
    when "static"
      :default
    when "ajax"
      :remote
    when "edit_aptc_csr"
      :remote_edit_aptc_csr
    when "disabled"
      nil # disabled dropdowns are not rendered on BS4
    end
  end

  def add_hbx_only_dropdowns(application, options)
    return options unless current_user.has_hbx_staff_role?
    options << (['faa.applications.actions.transfer_history', transfer_history_application_path(application), :default] if FinancialAssistanceRegistry.feature_enabled?(:transfer_history_page))
    options << (['faa.applications.actions.full_application', raw_application_application_path(application), :default] if current_user.has_hbx_staff_role? && application.is_reviewable?)
  end
end
