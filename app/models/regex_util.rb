# frozen_string_literal: true

module RegexUtil
  # Used for verifying that a string contains only numbers.
  # Example: hbx_id
  NUMBERS_ONLY_REGEX = /^[0-9]+$/

  # Used for verifying that a string is a valid hexadecimal number.
  # Example: BSON::ObjectId
  HEXADECIMAL_ONLY_REGEX = /^[0-9a-fA-F]+$/i

  # Used for verifying that a string contains only numbers and letters.
  # Example: external_id
  NUMBERS_AND_LETTERS_ONLY_REGEX = /^[0-9a-zA-Z]+$/
end
