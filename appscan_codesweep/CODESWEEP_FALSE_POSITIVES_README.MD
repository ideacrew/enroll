# AppScan CodeSweep
IdeaCrew currently uses the AppScan CodeSweep technology to run a security check on each PR that is raised against trunk. See [CodeSweep GitHub Workflow](/.github/workflows/codesweep.yml) for implementation details.

## False Positives
Multiple examples have been encountered where commonly used patterns in our Rails applications are triggering false positives, which results in a red build and blocks the peer review process. These false positives can incentivize messy code, antipatterns, etc. when developers alter implementation details just to work around the security check.

Currently, AppScan CodeSweep does not have an ignore list. This means that false positives that are found by AppScan CodeSweep need to be handled by us (IC staff) as part of our code release process.

## Protocol for Handling an AppScan CodeSweep Failure
The protocol below is now in place to handle false positives. It is subject to change as we learn more about the AppScan CodeSweep technology and as we gain more experience with it.

### Known False Positive
To determine if the CodeSweep failure is a known false positive, the author should check the [list of codesweep false positives](CODESWEEP_FALSE_POSITIVES.MD).

If the author believes they have reproduced a known false positive, then they must:
1. Add a note on the PR description indicating which false positive it matches in the [codesweep false positives](CODESWEEP_FALSE_POSITIVES.MD) list.
2. Tag a [Merge Shepherd](https://github.com/orgs/ideacrew/teams/merge-shepherds) on the PR for review.
3. Add a Security Review to the Pivotal ticket and assign it to the Merge Shepherd.

The Merge Shepherd is responsible for reviewing the PR and approving if it is a known false positive. This includes updating the Pivotal ticket's Security Review status to "Pass".

**Note:** a Merge Shepherd can act as both regular peer reviewer and security reviewer for a PR, however, these are distinct steps that need to be tracked separately. **The false positives protocol is in addition to the regular peer review process, NOT in place of it.**

If the Merge Shepherd believes the failure does not match a known false positive, then the author must follow the protocol below for adding a new false positive. (format as bullet list)

### New False Positive
When the author believes they have encountered a new false positive that is not present on the false positives list, then they must:
1. Add notes on the PR description describing why the failure is a false positive. Example: https://github.com/ideacrew/enroll/pull/3126
2. Tag the Security Manager([Desire Banse](https://github.com/desireB)) for security review.
3. Flag the PR to their Tech Lead to coordinate approvals from the Security Manager, Lead Product Engineer and Leadership (Angus Irvine).

The Lead Product Engineer (Sai K for IVL, Marco for Group, Kristin for DBH) is responsible for:
1. Getting approval from Desire for security review.
2. Getting approval from Angus to merge the PR with a red build into trunk.
3. Adding a comment on the ticket indicating the approval from Angus to merge the PR with a red build into trunk.

**IMPORTANT**: The build cannot be red for any reason other than the AppScan CodeSweep check.

The Security Manager is responsible for:
1. Reviewing the PR and approving if the CodeSweep failure is a false positive.
2. Updating the Pivotal ticket's Security Review status to "Pass".
3. Updating the [codesweep false positives](CODESWEEP_FALSE_POSITIVES.MD) list with the new false positive.

**IMPORTANT:** The [Security Manager](https://github.com/desireB) is codeowner of the CODESWEEP_FALSE_POSITIVES.MD file and is the only one who should update it.

### Real Security Issue
If the violation is deemed not to be a false positive, the author must fix the issue and pass the CodeSweep check before the PR can be merged.
