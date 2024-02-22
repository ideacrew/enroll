# frozen_string_literal: true

# Utility module to perform scrubbing and prevent XSS attacks.
module HtmlScrubberUtil
  # Sanitizes a given value using rails sanitizers.
  #
  # @param value [Object] The value to sanitize.
  # @return [ActiveSupport::SafeBuffer] The scrubbed value
  def sanitize_html(value)
    ActionController::Base.helpers.sanitize(
      value,
      tags: Loofah::HTML5::SafeList::ACCEPTABLE_ELEMENTS,
      attributes: Loofah::HTML5::SafeList::ACCEPTABLE_ATTRIBUTES.dup.add("style")
    ).html_safe
  end
end