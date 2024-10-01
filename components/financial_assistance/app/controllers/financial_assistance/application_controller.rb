# frozen_string_literal: true

module FinancialAssistance
  class ApplicationController < ::ApplicationController
    protect_from_forgery with: :exception
    include ::FileUploadHelper
    include ::L10nHelper

    before_action :verify_financial_assistance_enabled

    helper ::FinancialAssistance::Engine.helpers

    layout "layouts/financial_assistance"

    def load_support_texts
      file_path = lookup_context.find(
        'financial_assistance/shared/support_text', [], false, [], formats: [:yml]
      ).identifier
      raw_support_text = YAML.safe_load(File.read(file_path)).with_indifferent_access
      @support_texts = support_text_placeholders raw_support_text
    end

    private

    def find_application
      application_id = params[:application_id] || params[:id]
      @application = if current_user.try(:person).try(:agent?)
                       FinancialAssistance::Application.find_by(id: application_id)
                     else
                       FinancialAssistance::Application.find_by(id: application_id, family_id: get_current_person.financial_assistance_identifier)
                     end
    end

    def verify_financial_assistance_enabled
      return render(file: 'public/404.html', status: 404) unless ::EnrollRegistry.feature_enabled?(:financial_assistance)
      true
    end

    def support_text_placeholders(raw_support_text)
      return [] if @application.nil?
      raw_support_text.update(raw_support_text).each do |_key, value|
        value.gsub! '<application-applicable-year>', @application.assistance_year.to_s if value.include? '<application-applicable-year>'
      end
    end

    # Checks if the application is a renewal draft and, if so, sets a flash message and redirects to the applications path.
    #
    # @return [void]
    def check_for_uneditable_application
      # If the application is a renewal draft, the user should not be able to edit it.
      # The below line could be refactored to read from a constant or a setting in the future if we want to add more states where the application should not be editable.
      return unless @application&.renewal_draft?

      flash[:alert] = l10n('faa.flash_alerts.uneditable_application')
      redirect_to(applications_path) and return
    end

    def parse_date(string)
      return nil if string.empty?
      date_format = string.match(/\d{4}-\d{2}-\d{2}/) ? "%Y-%m-%d" : "%m/%d/%Y"
      Date.strptime(string, date_format)
    end
  end
end
