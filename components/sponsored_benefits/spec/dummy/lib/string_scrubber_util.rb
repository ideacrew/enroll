# frozen_string_literal: true

# Utility module to perform scrubbing on strings to prevent attacks.
module StringScrubberUtil
  # Regular expression to match non-hexadecimal characters.
  # This is used to sanitize inputs that should be hexadecimal numbers.
  # Any characters matched by this regular expression will be removed from the input.
  #
  # @example
  #   "123abcXYZ".gsub(NON_HEX_CHARACTERS_REGEX, '') # => "123abc"
  #
  # @return [Regexp]
  NON_HEX_CHARACTERS_REGEX = /[^0-9a-fA-F]/

  # Sanitizes a string by removing non-hexadecimal characters.
  #
  # @param [String] str the string to sanitize
  # @return [String] the sanitized string
  def sanitize_to_hex(str)
    str.to_s.gsub(NON_HEX_CHARACTERS_REGEX, '')
  end
end
