# frozen_string_literal: true

require 'rails_helper'

# This will check the git diff for all .html.erb files and match all non HTML/ERB tag substrings
# against all the translations in the database to assure translations are added to the file.

RSpec.describe "Branch Files Translations Spec" do
  # Returns an array of all available translations with special characters removed, downcased
  def branch_view_filenames
    `git diff --name-only origin/master HEAD | grep .html.erb`.strip.split("\n")
  end

  # TODO: This can be used in future functionality to check for translations availability
  # let(:all_translation_keys) do
  #  Translation.all.map { |translation| translation.value.gsub(/[^0-9a-z ]/i, '').gsub(/\d+/,"").downcase }
  # end

  # This array will hold strings which do not filter out from the #potential_untranslated_substrings method
  # due to ERB tag structuring or another reason
  # Valid Whitelist Example:
  # "product.hios_id, hbx_enrollment_id: hbx_enrollment.id, active_year: product.active_year}), remote: true)%&gt;"
  # The above string is part of an ERB tag, and is not potentially part of a translation
  # Invalid Whitelist Example:
  # "Coverage"
  # The above is a human readable string part of the HTMl and must be translated
  # DO NOT add to this list without checking with lead dev
  # TODO: Move to YML or other file
  def whitelisted_substrings
    # Here are substrings from spec/support/fake_view.html.erb which would fail the spec (comment this, spec will fail):
    [
      "Coverage", "product.hios_id, hbx_enrollment_id: hbx_enrollment.id, active_year: product.active_year}), remote: true)%&gt;",
      "/month", "Plan End:", "Reinstated Enrollment", "ID:", "0) %&gt;"
    ]
    # The only one of theses that are valid substrings whitelists are:
    # ["product.hios_id, hbx_enrollment_id: hbx_enrollment.id, active_year: product.active_year}), remote: true)%&gt;", "0) %&gt;"]
    # The rest are words that need to go in translation tags
  end

  # The following method will take the full read HTML.erb file and:
  # Return a string without all HTML/ERB Tags
  # Turn the string into an array, separated at each new line
  # Remove any blank strings from the array
  # Remove any white space from left and right of array elements
  # Remove white space to the left and right of sentences
  # Cut the array down to only the uniq elements
  # Remove any aray elements which are all special characters (I.E. "!", ":")
  # removes leading and ending extra whitespace, and blank strings, returning an array like:
  # ["list all attributes", "success"]
  # Further reading: https://stackoverflow.com/a/54405741/5331859
  def potential_untranslated_substrings(read_file)
    potential_substrings = ActionView::Base.full_sanitizer.sanitize(read_file).split("\n").reject!(&:blank?).map(&:strip).uniq.reject! do |substring|
      substring.split("").all? { |char| ('a'..'z').to_a.exclude?(char.downcase) }
    end
    # Non Whitelisted Untranslated Substrings
    potential_substrings.reject { |substring| whitelisted_substrings.include?(substring) }
  end

  it "should not have any untranslated substrings outside of HTML tags" do
    if branch_view_filenames.present?
      branch_view_filenames.each do |view_filename|
        read_file = File.read("#{Rails.root}/#{view_filename}")
        next unless read_file.present?
        unless potential_untranslated_substrings(read_file).empty?
          raise("The following are untranslated substrings. #{potential_untranslated_substrings(read_file)}. "\
            "Please modify your ERB and place them in translation helper tags "\
            "with a coorelating translation in db/seedfiles/translations or whitelist them in the #whitelisted_translation_substrings"\
            "method with lead dev permission.")
        end
        expect(potential_untranslated_substrings(read_file).length).to eq(0)
      end
    end
  end
end

