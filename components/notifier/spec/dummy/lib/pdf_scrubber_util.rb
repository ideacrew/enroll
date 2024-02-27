# frozen_string_literal: true

# Utility module to perform scrubbing and prevent XSS in pdfs.
module PdfScrubberUtil
  # Sanitizes a given value using a custom tag set.
  #
  # @param value [Object] The value to sanitize.
  # @return [ActiveSupport::SafeBuffer] The scrubbed value
  def sanitize_pdf(value)
    ActionController::Base.helpers.sanitize(
      value,
      tags: Loofah::HTML5::SafeList::ACCEPTABLE_ELEMENTS.dup.delete("select").add("style"),
      attributes: Loofah::HTML5::SafeList::ACCEPTABLE_ATTRIBUTES.dup.add("style")
    ).html_safe
  end
end