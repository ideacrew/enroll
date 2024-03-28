# frozen_string_literal: true

# The Gender class represents the gender information of a user.
# It includes fields for attested gender and sex assigned at birth.
# It also includes constants for defined gender options.
class Gender
    include Mongoid::Document
    include Mongoid::Timestamps

    extend L10nHelper

    # @!attribute [rw] demographics
    #   @return [Demographics] The demographics associated with the gender.
    #   This is an instance of the Demographics class.
    #   The Demographics class that the Gender class is embedded in.
    embedded_in :demographics, class_name: 'Demographics'
  
    # 'male', 'female', 'non_binary'
    # The gender options.
    # @return [Array<String>] An array of gender options.
    GENDER_OPTIONS = %w[male female non_binary].freeze
  
    # The mapping of gender options to their human readable forms.
    # @return [Hash] A hash mapping gender options to their human readable forms.
    GENDER_OPTIONS_MAPPING = {
      'male' => l10n('demographics.gender.male'),
      'female' => l10n('demographics.gender.female'),
      'non_binary' => l10n('demographics.gender.non_binary')
    }.freeze

    # 'male', 'female'
    # The sex assigned at birth options.
    # @return [Array<String>] An array of sex options.
    SEX_ASSIGNED_AT_BIRTH_OPTIONS = %w[male female].freeze

    # The attestation kinds.
    # @return [Array<String>] An array of attestation kinds.
    # We could expand ATTESTATION_KINDS to include 'self_attested' 'broker_attested' and 'admin_attested'.
    ATTESTATION_KINDS = %w[non_attested].freeze
  
    # @!attribute [rw] attestation
    #   @return [String, nil] The source of attestation for the gender information.
    #   This field is used to track the source of attestation.
    #   It can be updated with the value 'non_attested' when we do not have gender
    #   information when migrating from the old data model to the new data model.
    #   It is nil by default.
    field :attestation, type: String

    # @!attribute [rw] attested_gender
    #   @return [String, nil] The gender that the user has attested to.
    #   This is a string representing a gender.
    #   It is nil by default.
    field :attested_gender, type: String
  
    # @!attribute [rw] sex_assigned_at_birth
    #   @return [String, nil] The sex assigned at birth that the user has attested to.
    #   This is a string representing a sex.
    #   It is nil by default.
    field :sex_assigned_at_birth, type: String
  end
  