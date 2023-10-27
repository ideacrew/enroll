# AppScan CodeSweep
IdeaCrew currently uses the AppScan CodeSweep technology to run a security check on each PR that is raised against trunk. See [CodeSweep GitHub Workflow](/.github/workflows/codesweep.yml) for implementation details.

## False Positives
Multiple examples have been encountered where commonly used patterns in our Rails applications are triggering false positives, which results in a red build and blocks the peer review process.  Furthermore, these false positives can incentivize messy code, antipatterns, etc. when developers try to avoid the failure by altering implementation details just to workaround the security check.

Currently, AppScan CodeSweep does not have an ignore list. This means that false positives that are found by AppScan CodeSweep need to be handled by us (IC staff) as part of our code release process.

## Protocol to handle an AppScan CodeSweep Failure
The below protocol is now in place to handle false positives.  This protocol is subject to change as we learn more about the AppScan CodeSweep technology and as we gain more experience with it.

### Known False Positive
If the CodeSweep check fail is a known false positive, then
1. The author of the PR must do the below:
    1. Add notes on the PR description describing why the failure is a false positive. Example: https://github.com/ideacrew/enroll/pull/3126
    2. The author should add a comment indicating that the failure is a known false positive and which false positive it matches in the [codesweep false positives](CODESWEEP_FALSE_POSITIVES.MD).
    3. The author should tag [Merge Shepherds](https://github.com/orgs/ideacrew/teams/merge-shepherds) on the PR for approval to get this PR merged.
    4. The author should add Security Review on the ticket.
2. Merge Shepherd must do the below:
    1. Review the PR and approve if this is a known false positive. Also, Update the ticket's Security Review status to "Pass".
    2. If this is not a known false positive then the Merge Shepherd should tag the Security Manager([Desire Banse](https://github.com/desireB)) for review and approval. Security Manager will follow the steps in the next section.

### New False Positive
If the CodeSweep check fail is not a known false positive, then
1. The author of the PR must do the below:
    1. Add notes on the PR description describing why the failure is a false positive. Example: https://github.com/ideacrew/enroll/pull/3126
    3. The author should tag the Security Manager([Desire Banse](https://github.com/desireB)) on the PR for approval to get this PR merged.
    4. The author should add Security Review on the ticket and assign it to Security Manager.
    5. The author should flag this to their manager to get the approval from the Security Manager for security review and Angus to merge the PR with red build(only AppScan CodeSweep error) into trunk. Follow your management chain's hierarchy to get the approval.
2. Lead Product Engineer will do the below:
    1. Get an approval from Desire for security review.
    2. Get an approval Angus to merge the PR with red build into trunk.
    3. Add a comment on the ticket indicating the approval from Angus to merge the PR with red build into trunk.
3. Security Manager will do the below:
    1. Review the PR and approve if this is a false positive.
    2. Update the ticket's Security Review status to "Pass".
    3. Update the [codesweep false positives](CODESWEEP_FALSE_POSITIVES.MD) list with the new false positive.

**Note:** The [Security Manager](https://github.com/desireB) is codeowner of the CODESWEEP_FALSE_POSITIVES.MD file and is the only one who should update it.

### Real Security Issue
If the violation is deemed not to be a false positive, the author must fix the issue and pass the CodeSweep check before the PR can be merged.
