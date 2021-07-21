# frozen_string_literal: true

module FinancialAssistance
  class ApplicationController < ::ApplicationController
    protect_from_forgery with: :exception

    before_action :verify_financial_assistance_enabled

    helper ::FinancialAssistance::Engine.helpers

    layout "layouts/financial_assistance"

    def load_support_texts
      file_path = lookup_context.find_template("financial_assistance/shared/support_text.yml").identifier
      raw_support_text = YAML.safe_load(File.read(file_path)).with_indifferent_access
      @support_texts = support_text_placeholders raw_support_text
    end

    private

    def financial_assistance_engine_enabled?
      FinancialAssistanceRegistry.feature_enabled?(:financial_assistance)
    end

    def verify_financial_assistance_enabled
      redirect_to "/" unless financial_assistance_engine_enabled?
    end

    def support_text_placeholders(raw_support_text)
      return [] if @application.nil?
      raw_support_text.update(raw_support_text).each do |_key, value|
        value.gsub! '<application-applicable-year>', @application.assistance_year.to_s if value.include? '<application-applicable-year>'
      end
    end
  end
end
