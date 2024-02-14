# frozen_string_literal: true

# The Race class represents the race information of a user.
# It includes fields for attested races and other race (if 'other' is selected).
# It also includes constants for defined race options, other race options, CMS reporting groups, and their mappings.
class Race
  include Mongoid::Document
  include Mongoid::Timestamps

  # @!attribute [rw] demographics
  #   @return [Demographics] The demographics associated with the race.
  #   This is an instance of the Demographics class.
  #   The Demographics class that the Race class is embedded in.
  embedded_in :demographics, class_name: 'Demographics'

  # The defined race options.
  # @return [Array<String>] An array of defined race options.
  DEFINED_RACE_OPTIONS = %w[
    white black_or_african_american asian_indian chinese filipino japanese korean
    vietnamese other_asian samoan native_hawaiian guamanian_or_chamorro
    other_pacific_islander american_indian_or_alaskan_native other
  ].freeze

  # The mapping of defined race options to their display names or reporting names.
  # @return [Hash] A hash mapping defined race options to their display names or reporting names.
  DEFINED_RACE_OPTIONS_MAPPING = {
    'white' => 'White',
    'black_or_african_american' => 'Black or African American',
    'asian_indian' => 'Asian Indian',
    'chinese' => 'Chinese',
    'filipino' => 'Filipino',
    'japanese' => 'Japanese',
    'korean' => 'Korean',
    'vietnamese' => 'Vietnamese',
    'other_asian' => 'Other Asian',
    'samoan' => 'Samoan',
    'native_hawaiian' => 'Native Hawaiian',
    'guamanian_or_chamorro' => 'Guamanian or Chamorro',
    'other_pacific_islander' => 'Other Pacific Islander',
    'american_indian_or_alaskan_native' => 'American Indian or Alaskan Native',
    'other' => 'Other'
  }.freeze

  # The undefined race options.
  # @return [Array<String>] An array of undefined race options.
  UNDEFINED_RACE_OPTIONS = %w[do_not_know refused].freeze

  # The mapping of undefined race options to their human readable forms.
  # @return [Hash] A hash mapping undefined race options to their human readable forms.
  UNDEFINED_RACE_OPTIONS_MAPPING = { 'do_not_know' => 'Do not know', 'refused' => 'Choose not to answer' }.freeze

  # The combined race options.
  # @return [Array<String>] An array of all race options.
  RACE_OPTIONS = (DEFINED_RACE_OPTIONS + UNDEFINED_RACE_OPTIONS).freeze

  # The CMS reporting group kinds.
  # @return [Array<String>] An array of CMS reporting group kinds.
  CMS_REPORTING_GROUP_KINDS = %w[
    white black_or_african_american american_indian_or_alaska_native asian
    native_hawaiian_or_other_pacific_islander multi_racial
  ].freeze

  # The mapping of CMS reporting group kinds to their human readable forms.
  # @return [Hash] A hash mapping CMS reporting group kinds to their human readable forms.
  CMS_REPORTING_GROUP_KINDS_MAPPING = {
    'white' => 'White',
    'black_or_african_american' => 'Black or African American',
    'american_indian_or_alaska_native' => 'American Indian or Alaska Native',
    'asian' => 'Asian',
    'native_hawaiian_or_other_pacific_islander' => 'Native Hawaiian or Other Pacific Islander',
    'multi_racial' => 'Multi Racial',
    'unknown' => 'Unknown'
  }.freeze

  # The Races for each CMS reporting groups.
  # @return [Array<String>] An array of Races for each CMS reporting groups.
  RACES_FOR_CMS_GROUP_WHITE = %w[white].freeze
  RACES_FOR_CMS_GROUP_BLACK_OR_AFRICAN_AMERICAN = %w[black_or_african_american].freeze
  RACES_FOR_CMS_GROUP_AMERICAN_INDIAN_OR_ALASKA_NATIVE = %w[american_indian_or_alaska_native].freeze
  RACES_FOR_CMS_GROUP_ASIAN = %w[asian_indian chinese filipino japanese korean vietnamese other_asian].freeze
  RACES_FOR_CMS_GROUP_NATIVE_HAWAIIAN_OR_OTHER_PACIFIC_ISLANDER = %w[samoan native_hawaiian guamanian_or_chamorro other_pacific_islander].freeze
  RACES_FOR_CMS_GROUP_UNKNOWN = %w[do_not_know refused].freeze

  # The attestation kinds.
  # @return [Array<String>] An array of attestation kinds.
  # We could expand ATTESTATION_KINDS to include 'self_attested' 'broker_attested' and 'admin_attested'.
  ATTESTATION_KINDS = %w[non_attested].freeze

  # @!attribute [rw] attestation
  #   @return [String, nil] The source of attestation for the ethnicity information.
  #   This field is used to track the source of attestation.
  #   It can be updated with the value 'non_attested' when we do not have ethnicity
  #   information when migrating from the old data model to the new data model.
  #   It is nil by default.
  field :attestation, type: String

  # @!attribute [rw] attested_races
  #   @return [Array<String>] The list of races that the user has attested to.
  #   This is an array of strings, with each string representing a race.
  #   The array is empty by default.
  field :attested_races, type: Array, default: []

  # @!attribute [rw] other_race
  #   @return [String, nil] The race specified by the user if they selected 'other' as an option.
  #   This is a free text field that can be used to specify the race.
  #   It is nil by default.
  field :other_race, type: String

  # Returns the CMS reporting group based on the attested races.
  #
  # @return [String, nil] The CMS reporting group.
  #   Returns nil if attested_races is empty.
  #   Returns 'white' if attested_races has only 'white' as a value.
  #   Returns 'black_or_african_american' if attested_races has only 'black_or_african_american' as a value.
  #   Returns 'american_indian_or_alaska_native' if attested_races has only 'american_indian_or_alaska_native' as a value.
  #   Returns 'asian' if attested_races has any and only values from 'asian_indian', 'chinese', 'filipino', 'japanese', 'korean', 'vietnamese', 'other_asian'.
  #   Returns 'native_hawaiian_or_other_pacific_islander' if attested_races has any and only values from 'samoan', 'native_hawaiian', 'guamanian_or_chamorro', 'other_pacific_islander'.
  #   Returns 'unknown' if attested_races has any and only 'do_not_know' or 'refused'.
  #   Returns 'multi_racial' if attested_races has any other combination of values.
  def cms_reporting_group
    return nil if attested_races.empty?
    return 'white' if (attested_races - RACES_FOR_CMS_GROUP_WHITE).empty?
    return 'black_or_african_american' if (attested_races - RACES_FOR_CMS_GROUP_BLACK_OR_AFRICAN_AMERICAN).empty?
    return 'american_indian_or_alaska_native' if (attested_races - RACES_FOR_CMS_GROUP_AMERICAN_INDIAN_OR_ALASKA_NATIVE).empty?
    return 'asian' if (attested_races - RACES_FOR_CMS_GROUP_ASIAN).empty?
    return 'native_hawaiian_or_other_pacific_islander' if (attested_races - RACES_FOR_CMS_GROUP_NATIVE_HAWAIIAN_OR_OTHER_PACIFIC_ISLANDER).empty?
    return 'unknown' if (attested_races - RACES_FOR_CMS_GROUP_UNKNOWN).empty?

    'multi_racial'
  end
end
