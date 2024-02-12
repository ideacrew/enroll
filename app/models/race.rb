# frozen_string_literal: true

class Race
  include Mongoid::Document
  include Mongoid::Timestamps

  embedded_in :demographics, class_name: 'Demographics'

  # 'White', 'Black or African American', 'Asian Indian', 'Chinese', 'Filipino',
  # 'Japanese', 'Korean', 'Vietnamese', 'Other Asian', 'Samoan', 'Native Hawaiian',
  # 'Guamanian or Chamorro', 'Other Pacific Islander', 'American Indian or Alaskan Native',
  # 'Other', 'Do not know', 'Refused'(OR 'Choose not to answer')
  DEFINED_RACE_OPTIONS = [
    'White', 'Black or African American', 'Asian Indian', 'Chinese', 'Filipino',
    'Japanese', 'Korean', 'Vietnamese', 'Other Asian', 'Samoan', 'Native Hawaiian',
    'Guamanian or Chamorro', 'Other Pacific Islander', 'American Indian or Alaskan Native', 'Other'
  ]

  OTHER_RACE_OPTIONS = ['Do not know', 'Refused']

  RACE_OPTIONS = DEFINED_RACE_OPTIONS + OTHER_RACE_OPTIONS

  CMS_REPORTING_GROUPS = [
    'White', 'Black or African American',
    'American Indian or Alaska Native', 'Asian',
    'Native Hawaiian or Other Pacific Islander',
    'Multi Racial'
  ]

  field :attested_races, type: Array, default: []

  field :other_race, type: String

  # TODO: Add logic to return the CMS reporting group based on the attested_enhtnicities
  def cms_reporting_group; end
end

# TODO: Add YARD documentation for the class, fields, constants and methods.
#       Add required scopes for the fields.
#       Add any additional methods required for the class.
#       Add tests for the class and methods
