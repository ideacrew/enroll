# frozen_string_literal: true

require 'rails_helper'

class ErbTranslationsLinter
  attr_accessor :read_files, :whitelisted_translation_strings_from_erb_tags, :whitelisted_non_erb_tag_strings

  def initialize(read_files = nil, whitelisted_translation_strings_from_erb_tags = nil, whitelisted_non_erb_tag_strings = nil)
    @read_files = read_files
    @whitelisted_translation_strings_from_erb_tags = whitelisted_translation_strings_from_erb_tags
    @whitelisted_non_erb_tag_strings = whitelisted_non_erb_tag_strings
  end

  def all_translations_in_erb_tags?
    read_files.each do |read_file|
      return false unless no_potential_untranslated_substrings_in_erb_tags?(read_file)
    end
    true
  end

  def all_translations_outside_erb_tags?
    read_files.each do |read_file|
      return false unless no_potential_untranslated_non_erb_strings?(read_file)
    end
    true
  end

  # The following method will take the full read HTML.erb file and:
  # Return a string without all HTML/ERB Tags
  # Turn the string into an array, separated at each new line
  # Remove any blank strings from the array
  # Remove any white space from left and right of array elements
  # Remove white space to the left and right of sentences
  # Cut the array down to only the uniq elements
  # Remove any array elements which are all special characters (I.E. "!", ":")
  # removes leading and ending extra whitespace, and blank strings, returning an array like:
  # ["list all attributes", "success"]
  # Further reading: https://stackoverflow.com/a/54405741/5331859
  def no_potential_untranslated_non_erb_strings?(read_file)
    potential_substrings = ActionView::Base.full_sanitizer.sanitize(read_file).split("\n").reject!(&:blank?).map(&:strip).uniq.reject! do |substring|
      substring.split("").all? { |char| ('a'..'z').to_a.exclude?(char.downcase) }
    end
    non_whitelisted_substrings = potential_substrings.reject { |substring| whitelisted_non_erb_tag_strings.include?(substring) }
    return true if non_whitelisted_substrings.blank?
    raise(untranslated_warning_message(non_whitelisted_substrings))
  end

  # The following method contains ERB methods which will appear between ERB tags, but not require translation.
  # For example, if an ERB tag's stringified content contains the substring "l10n", we can be confident that it is already translated.
  # On the other hand, if the ERB tag's stringified content is something like "hbx_enrollment.effective_on",
  # it is just returning a date which doess not need to be translated
  def no_potential_untranslated_substrings_in_erb_tags?(read_file)
    potential_substrings = read_file.scan(/<%=(.*)%>/)
    non_whitelisted_substrings = potential_substrings.flatten.reject { |substring| whitelisted_translation_strings_from_erb_tags.any? { |whitelisted_substring| substring.include?(whitelisted_substring) } }
    return true if non_whitelisted_substrings.blank?
    raise(untranslated_warning_message(non_whitelisted_substrings))
  end

  def untranslated_warning_message(non_whitelisted_substrings)
    "The following are potentially untranslated substrings. #{non_whitelisted_substrings.join(', ')}. "\
    "Please modify your ERB and place them in translation helper tags "\
    "with a coorelating translation or whitelist them in the whitelisted substring hash."
  end
end
