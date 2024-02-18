# frozen_string_literal: true

# The SanitizeConcern module provides a method for sanitizing input values.
# It is intended to be used as a mixin to add sanitization functionality to any class.
module SanitizeConcern
  extend ActiveSupport::Concern

  included do
    # Sanitizes a given value if it is a string.
    # It uses the full sanitizer provided by ActionView::Base to strip all HTML tags from the string, leaving only the text content.
    # This is used to prevent cross-site scripting (XSS) attacks by ensuring that any user-supplied input is safe to display in a view.
    #
    # @param value [Object] The value to sanitize.
    # @return [Object] The sanitized value if it was a string, or the original value if it was not a string.
    def sanitize(value)
      return value unless value.is_a?(String)

      ::ActionView::Base.full_sanitizer.sanitize(value)
    end
  end
end
