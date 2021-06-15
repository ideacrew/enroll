# frozen_string_literal: true

# This file is added to resolve gemfile and rspec requirement, revisit or remove this initializer when no longer needed
StimulusReflex.configure do |config|
  config.on_failed_sanity_checks = :warn
end
