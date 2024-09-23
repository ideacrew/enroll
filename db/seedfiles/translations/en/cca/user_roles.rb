# This hash maps user role identifiers to their human-readable translations.
# It is used throughout the application to display user roles in a more understandable format.
# Each key follows the pattern 'en.user_roles.<role_identifier>' to denote that these are English translations
# for user roles. The value associated with each key is the translated string that represents the user role in English.
#
# @example How to access a translation by using the L10nHelper module:
#   include L10nHelper
#   # This will return 'Assister'
#   l10n('user_roles.assister') # => 'Assister'
USER_ROLES_TRANSLATIONS = {
  'en.user_roles.assister' => 'Assister',
  'en.user_roles.broker' => 'Broker',
  'en.user_roles.broker_agency_staff' => 'Broker Agency Staff',
  'en.user_roles.consumer' => 'Consumer',
  'en.user_roles.csr' => 'CSR',
  'en.user_roles.employee' => 'Employee',
  'en.user_roles.employer_staff' => 'Employer Staff',
  'en.user_roles.general_agency_staff' => 'General Agency Staff',
  'en.user_roles.hbx_staff' => 'HBX Staff',
  'en.user_roles.resident' => 'Resident'
}
