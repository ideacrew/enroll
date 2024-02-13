# frozen_string_literal: true

# The Ethnicity class represents the ethnicity information of a user.
# It includes fields for attested ethnicities and other ethnicity (if 'other' is selected).
# It also includes constants for defined ethnicity options, other ethnicity options, CMS reporting groups, and their mappings.
class Ethnicity
  include Mongoid::Document
  include Mongoid::Timestamps

  # @!attribute [rw] demographics
  #   @return [Demographics] The demographics associated with the ethnicity.
  #   This is an instance of the Demographics class.
  #   The Demographics class that the Ethnicity class is embedded in.
  embedded_in :demographics, class_name: 'Demographics'

  # 'Cuban', 'Mexican, Mexican American or Chicano/a', 'Puerto Rican', 'Other'
  # The ethnicity options.
  # @return [Array<String>] An array of ethnicity options.
  ETHNICITY_OPTIONS = %w[
    cuban mexican_mexican_american_or_chicano puerto_rican other
  ].freeze

  # The mapping of ethnicity options to their human readable forms.
  # @return [Hash] A hash mapping ethnicity options to their human readable forms.
  ETHNICITY_OPTIONS_MAPPING = {
    'cuban' => 'Cuban',
    'mexican_mexican_american_or_chicano' => 'Mexican, Mexican American or Chicano/a',
    'puerto_rican' => 'Puerto Rican',
    'other' => 'Other'
  }.freeze

  # The CMS reporting group kinds.
  # @return [Array<String>] An array of CMS reporting group kinds.
  CMS_REPORTING_GROUP_KINDS = %w[hispanic_or_latino not_hispanic_or_latino unknown].freeze

  # The mapping of CMS reporting group kinds to their human readable forms.
  # @return [Hash] A hash mapping CMS reporting group kinds to their human readable forms.
  CMS_REPORTING_GROUP_KINDS_MAPPING = {
    'hispanic_or_latino' => 'Hispanic or Latino',
    'not_hispanic_or_latino' => 'Not Hispanic or Latino'
  }.freeze

  # The defined hispanic or latino options.
  # @return [Array<String>] An array of defined hispanic or latino options.
  HISPANIC_OR_LATINO_OPTIONS = %w[yes no do_not_know refused].freeze

  # The mapping of defined hispanic or latino options to their display names.
  # @return [Hash] A hash mapping defined hispanic or latino options to their display names.
  HISPANIC_OR_LATINO_OPTIONS_MAPPING = {
    'yes' => 'Yes',
    'no' => 'No',
    'do_not_know' => 'Do not know',
    'refused' => 'Choose not to answer' # 'Refused'
  }.freeze

  # @!attribute [rw] hispanic_or_latino
  #   @return [String] The hispanic or latino option that the user has selected.
  #   This is a string that represents the hispanic or latino option.
  #   It is nil by default.
  field :hispanic_or_latino, type: String

  # @!attribute [rw] attested_ethnicities
  #   @return [Array<String>] The list of ethnicities that the user has attested to.
  #   This is an array of strings, with each string representing an ethnicity.
  #   The array is empty by default.
  field :attested_ethnicities, type: Array, default: []

  # @!attribute [rw] other_ethnicity
  #   @return [String, nil] The ethnicity specified by the user if they selected 'other' as an option.
  #   This is a free text field that can be used to specify the ethnicity.
  #   It is nil by default.
  field :other_ethnicity, type: String

  # Returns the CMS reporting group based on the attested races.
  #
  # @return [String] The CMS reporting group.
  def cms_reporting_group
    hispanic_or_latino == 'yes' ? 'hispanic_or_latino' : 'not_hispanic_or_latino'
  end
end
