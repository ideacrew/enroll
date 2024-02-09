# frozen_string_literal: true

# This file is used for the rare environment variable that must be set in
# order for the cucumbers to pass, but can't be mocked.  An example of this is
# a feature flag which controls the loading order of files or class
# initialization, and thus is only run once.
ENV['PREVENT_CONCURRENT_SESSIONS_IS_ENABLED'] = "true"