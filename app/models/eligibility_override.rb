# frozen_string_literal: true

# Represents an eligibility override for a member
class EligibilityOverride
  include Mongoid::Document
  include Mongoid::Timestamps

  embedded_in :member_determination

    # The override rule that was applied.
  field :override_rule, type: String

    # Whether or not the override was applied.
  field :override_applied, type: Boolean

end
