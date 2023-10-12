# frozen_string_literal: true

module ActiveSupport
  module Callbacks
    # Enhance Active Support callbacks with the following methods that enable us to modify records without invoking callbacks.
    module ClassMethods
      def without_callback(*args)
        skip_callback(*args)
        result = yield
        set_callback(*args)
        result
      rescue StandardError
        set_callback(*args)
        result
      end

      def without_callbacks(callback_options)
        callback_options.each { |args| skip_callback(*args) }
        result = yield
        callback_options.each { |args| set_callback(*args) }
        result
      rescue StandardError
        callback_options.each { |args| set_callback(*args) }
        result
      end
    end
  end
end
