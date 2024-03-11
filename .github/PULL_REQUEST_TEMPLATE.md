# PR Checklist

Please check if your PR fulfills the following requirements
- [ ] The title follows our [guidelines](https://github.com/ideacrew/enroll/blob/trunk/CONTRIBUTING.md#commit
)
- [ ] Tests for the changes have been added (for bugfixes/features)

# PR Type
What kind of change does this PR introduce?

- [ ] Bugfix
- [ ] Feature (requires Feature flag)
- [ ] Data fix or migration (inert code, no impact until run)
- [ ] Refactoring (no functional changes, no API changes)
- [ ] Build related changes
- [ ] CI related changes
- [ ] Dependency updates (e.g., add a new gem or updated to a version)

# What is the ticket # detailing the issue?

Ticket: 

# A brief description of the changes

Current behavior:

New behavior:

# Feature Flag

For all new feature development, a feature flag is required to control the exposure of the feature to our end users. A feature flag needs a corresponding environment variable that is used to initialize the state of the flag. Please share the name of the environment variable below that would enable/disable the feature and which client(s) it applies to.

Variable name:

- [ ] DC
- [ ] ME

# Additional Context
Include any additional context that may be relevant to the peer review process.

# AppScan CodeSweep Failure
In the event of a failed check on the AppScan CodeSweep step of our GitHub Actions workflow, please review the False Positive protocol outlined here: appscan_codesweep/CODESWEEP_FALSE_POSITIVES_README.MD

Add all required notes to this section if the failure is a suspected false positive.