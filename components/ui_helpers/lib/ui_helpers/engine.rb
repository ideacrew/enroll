# frozen_string_literal: true

require 'rails'

module UIHelpers
  class Engine < ::Rails::Engine
    isolate_namespace UIHelpers
  end
end
