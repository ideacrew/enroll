# AppScan CodeSweep
IdeaCrew currently uses the AppScan CodeSweep technology to run a security check on each PR that is raised against trunk.  (See .github/workflows/codesweep.yml for implementation details)

## What's happning right now.
Currently, AppScan CodeSweep does not have an ignore list. This means that any false positives that are found by AppScan CodeSweep will need to be handled as part of our code release process. This is a manual process that will need to be done by the author of the Pull Request. The following steps will need to be taken to handle a false positive:

Please make sure to get approval from Desire if you see false positives with the AppScan CodeSweep errors.
    1. We need to document the reasons why it is a false positive on the PR with notes.
    2. Add Security Review on the ticket and get this approved by Desire.
    3. Get an approval from Angus to merge the PR with red build(only AppScan CodeSweep error) into trunk. Please follow your management chain's hierarchy for this approval.

Example: https://github.com/ideacrew/enroll/pull/3126. This PR has a section "AppScan CodeSweep Failure" where Trey added detailed information about the failure and why it is a false positive.

## What should happen moving forward.
    1. One page which explains the AppScan CodeSweep which also includes the current process and the future process on how to handle False Positives.
    2. This page has the list of all the false positives that we have seen so far and the reasons why they are false positives.
        1. Desire will be the code owner of this page and will be responsible for updating this page.
        2. What are all the things Desire is reponsible for?
            i. Review the PR notes and approve the PR.
            ii. Update the security review on the ticket.
            iii. Update this page with the new false positive.
        3. What are all the things Merge Shepherds are responsible for?
            i. Review the PR notes.
                a. Approve the PR if this is a known false positive. Update the security review on the ticket.
                b. Bring in Desire to review the PR notes if this is a new false positive.
        4. What if this is a real security issue?
            i. Follow the current process. Current process it to fix this as part of the PR and bring in your Tech Lead for additional support.
            ii. Sometime we will merge this into trunk before we QA this.
            iii. Sometime we will not merge this into trunk before we QA this.
        5. Update the Pull Request template to include AppScan CodeSweep Failure section.
        6. Add Desire as codeowner on the Codesweep false positives markdown page.

Add these markdown files into a folder named `appscan_codesweep` at the root.

### The below goes into the page that explains the AppScan CodeSweep

## AppScan Code Sweep failure

### False Positive:

### Real Security Issue:

Note in unanet `AppScan CodeSweep Process Update` and bill it to DC Maintenance
