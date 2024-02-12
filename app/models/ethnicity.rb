# frozen_string_literal: true

class Ethnicity
  include Mongoid::Document
  include Mongoid::Timestamps

  embedded_in :demographics, class_name: 'Demographics'

  # 'Cuban', 'Mexican, Mexican American or Chicano/a', 'Puerto Rican', 'Other'
  DEFINED_ETHNICITY_OPTIONS = [
    'Cuban',
    'Mexican',
    'Mexican American or Chicanoa',
    'Puerto Rican'
  ]

  OTHER_ETHNICITY_OPTIONS = ['Other']

  ETHNICITY_OPTIONS = DEFINED_ETHNICITY_OPTIONS + OTHER_ETHNICITY_OPTIONS

  CMS_REPORTING_GROUP_KINDS = ['Hispanic or Latino', 'Not Hispanic or Latino', 'Unknown']

  HISPANIC_OR_LATINO_OPTIONS = ['Yes', 'No', 'Do not Know', 'Refused']

  # Yes, No, Don't Know, Refused
  # Yes => Hispanic or Latino
  # No => Not Hispanic or Latino
  # Do not Know => Unknown
  # Refused => Unknown
  field :hispanic_or_latino, type: String

  field :attested_ethnicities, type: Array, default: []

  field :other_ethnicity, type: String

  # TODO: Add logic to return the CMS reporting group based on the attested_enhtnicities
  def cms_reporting_group; end
end

# TODO: Add YARD documentation for the class, fields, constants and methods.
#       Add required scopes for the fields.
#       Add any additional methods required for the class.
#       Add tests for the class and methods
