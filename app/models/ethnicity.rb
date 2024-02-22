# frozen_string_literal: true

# The Ethnicity class represents the ethnicity information of a user.
# It includes fields for attested ethnicities and other ethnicity (if 'other' is selected).
# It also includes constants for defined ethnicity options, other ethnicity options, CMS reporting groups, and their mappings.
class Ethnicity
  include Mongoid::Document
  include Mongoid::Timestamps

  extend L10nHelper

  # @!attribute [rw] demographics
  #   @return [Demographics] The demographics associated with the ethnicity.
  #   This is an instance of the Demographics class.
  #   The Demographics class that the Ethnicity class is embedded in.
  embedded_in :demographics, class_name: 'Demographics'

  # 'Cuban', 'Mexican, Mexican American or Chicano/a', 'Puerto Rican', 'Other'
  # The ethnicity options.
  # @return [Array<String>] An array of ethnicity options.
  ETHNICITY_OPTIONS = %w[cuban mexican_mexican_american_or_chicano puerto_rican other].freeze

  # The mapping of ethnicity options to their human readable forms.
  # @return [Hash] A hash mapping ethnicity options to their human readable forms.
  ETHNICITY_OPTIONS_MAPPING = {
    'cuban' => l10n('demographics.ethnicity.cuban'),
    'mexican_mexican_american_or_chicano' => l10n('demographics.ethnicity.mexican_mexican_american_or_chicano'),
    'puerto_rican' => l10n('demographics.ethnicity.puerto_rican'),
    'other' => l10n('other')
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
    'yes' => l10n('yes'),
    'no' => l10n('no'),
    'do_not_know' => l10n('do_not_know'),
    'refused' => l10n('refused')
  }.freeze

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

  # Returns the human readable form of the CMS reporting group.
  #
  # @return [String, nil] The human readable form of the CMS reporting group.
  # This method is only expected to be used in reports.
  def human_readable_cms_reporting_group
    CMS_REPORTING_GROUP_KINDS_MAPPING[cms_reporting_group]
  end

  # Returns the CMS reporting group based on the attested races.
  #
  # @return [String, nil] The CMS reporting group.
  #   when hispanic_or_latino is nil then it returns nil.
  def cms_reporting_group
    case hispanic_or_latino
    when 'yes'
      'hispanic_or_latino'
    when 'no', 'do_not_know', 'refused'
      'not_hispanic_or_latino'
    end
  end
end
