# frozen_string_literal: true

require 'brakeman/checks/base_check'

module Brakeman
  # Check for usage of 'html_safe'
  class CheckEngineHtmlSafeUsage < Brakeman::BaseCheck
    Brakeman::Checks.add self

    # rubocop:disable Style/ClassVars
    @@description = "Check for usage of 'html_safe' in a view action"
    # rubocop:enable Style/ClassVars

    def run_check
      tracker.find_call(:method => :html_safe).each do |result|
        warn :confidence => :medium,
             :warning_type => "Usage of html_safe",
             :warning_code => :cross_site_scripting,
             :message => "html_safe used",
             :cwe_id => [79],
             :result => result
      end
    end
  end
end