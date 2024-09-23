# frozen_string_literal: true

# This module is a utility module that provides methods to interact with gems.
module GemUtils
  require 'bundler'

  # Retrieves the SHA of the aca_entities gem.
  #
  # @return [String, nil] the SHA of the aca_entities gem, or nil if not found.
  def self.aca_entities_sha
    return @aca_entities_sha if defined?(@aca_entities_sha)

    spec = Bundler.load.specs.find { |s| s.name == 'aca_entities' }
    @aca_entities_sha = spec&.source&.revision
  end
end
