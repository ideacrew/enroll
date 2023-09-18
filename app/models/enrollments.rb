# frozen_string_literal: true

module Enrollments
  # Describes various reasons for enrollment termination.
  module TerminationReasons
    # The following reason indicates an enrollment was canceled via by
    # coverage which replaces it 'as if it has never happened'.
    # Downstream systems, such as GlueDB, should not be notified of this
    # transition.
    SUPERSEDED_SILENT = "superseded_silent"
  end

  # Stores the AASM states as hard values.
  #
  # While these values are present as the name of the AASM states, there are a
  # number of areas where we need to do string comparisons, so we centralize
  # those values here.
  module WorkflowStates
    COVERAGE_SELECTED = "coverage_selected"
    COVERAGE_CANCELED = "coverage_canceled"
    COVERAGE_TERMINATED = "coverage_terminated"
  end
end