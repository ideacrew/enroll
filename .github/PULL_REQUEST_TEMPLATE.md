# PR Checklist

Please check if your PR fulfills the following requirements:
- [ ] The title follows our [guidelines](https://github.com/ideacrew/enroll/blob/trunk/CONTRIBUTING.md#commit)
- [ ] Tests for the changes have been added (for bugfixes/features), and they use `let` helpers and `before` blocks.
- [ ] For all UI changes, there is Cucumber coverage.
- [ ] Any endpoint touched in the PR has an appropriate Pundit policy. For open endpoints, the reasoning is documented in the PR and code.
- [ ] Any endpoint modified in the PR only responds to the expected MIME types.
- [ ] For all scripts or rake tasks, how to run them is documented in both the PR and the code.
- [ ] There are no inline styles added.
- [ ] There is no inline JavaScript added.
- [ ] There is no hard-coded text added/updated in helpers/views/JavaScript. New/updated translation strings do not include markup/styles unless there is supporting documentation.
- [ ] Code does not use `.html_safe`.
- [ ] All images added/updated have alt text.
- [ ] Does not bypass RuboCop rules in any way.

# PR Type
What kind of change does this PR introduce?:

- [ ] Bugfix
- [ ] Feature (requires Feature flag)
- [ ] Data fix, Migration or Report (inert code, no impact until run)
- [ ] Refactoring (no functional changes, no API changes)
- [ ] Build related changes
- [ ] CI related changes
- [ ] Dependency updates (e.g., add a new gem or update to a version)

# What is the ticket # detailing the issue?

Ticket: 

# A brief description of the changes:

Current behavior:

New behavior:

# Feature Flag

For all new feature development, a feature flag is required to control the exposure of the feature to our end users. A feature flag needs a corresponding environment variable to initialize the state of the flag. Please share the name of the environment variable below that would enable/disable the feature and indicate which client(s) it applies to.

Variable name:

- [ ] DC
- [ ] ME

# Additional Context
Include any additional context that may be relevant to the peer review process.