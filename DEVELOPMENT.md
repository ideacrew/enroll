# Development at IdeaCrew

## Branching

At IdeaCrew, we follow [Trunk Based Development](https://trunkbaseddevelopment.com/). The philosophical goal of Trunk Based Development is to limit the distance between any new work in progress and the shared branch, Trunk.

Branches are created from trunk when development of a new feature or bug fix begins. We expect branches to live less than one week, but ideally one to two days. If you are unable to start and finish work in this timeframe, it may be a sign that work is not properly broken down.

## Pull Requests

Prior to integrating a feature branch back into Trunk, a Pull Request is required. This should be initiated in the GitHub UI at the appropriate repository page. For the Enroll, please ensure the correct base repository is selected, as ideacrew/enroll is a fork of an upstream repository.

When opening a Pull Request, make sure to include a reference to the Ticket that explains the code change being requested.

Pull requests require the approval of two other developers. One should be someone that is familiar with the Ticket, can evaluate the proposed solution, and provide feedback if needed. The other required approval will come from someone within the Merge Shepherd’s team. This team exists to make sure the quality of code coming into Trunk remains high.

## Deployment

After Pull Requests are merged to trunk, a GitHub Actions workflow runs and builds a docker image from that commit. These docker images are publicly available and take on the form:

ghcr.io/ideacrew/<repository>:trunk-<commit sha> (and may include a -dc or -me suffix)

## Security

The following are protections and mitigations that prevent malicious code, bad actors, and (more commonly) typical human behavior from adversely affecting the default branch, from which we regularly deploy to production. Much of this information can be found in the [Software Supply Chain Security Guide](https://github.com/aquasecurity/chain-bench/blob/main/docs/CIS-Software-Supply-Chain-Security-Guide-v1.0.pdf) published by the Center for Internet Security.

For our default branch, `trunk`, the following protections are in place:

- Ensure previous approvals are dismissed when updates are introduced to a code change proposal
- Ensure that there are restrictions on who can dismiss code change reviews
- Ensure code owners are set for extra sensitive code or configuration
- Ensure code owner’s review is required when a change affects owned code
- Ensure all checks have passed before the merge of new code
- Ensure open git branches are up to date before they can be merged into codebase
- Ensure all open comments are resolved before allowing to merge code changes
- Ensure pushing of new code is restricted to specific individuals or teams
- Ensure force pushes code to branches is denied
- Ensure branch deletions are denied
- Ensure any merging of code is automatically scanned for risks
- Ensure any change to code receives approval of two strongly authenticated users

Additionally, for all code pushed to any branch, [signed commits](https://docs.github.com/en/authentication/managing-commit-signature-verification/signing-commits) are required.

## Feature Development

Because we use Trunk Based Development and have to support multiple tenants (IdeaCrew refers to these tenants as Clients) of the same codebase, we use [Feature Flags](https://trunkbaseddevelopment.com/feature-flags/) to control the capabilities of our applications and services. Currently, we do this through a couple layers of indirection.

### Resource Registry

The Resource Registry is a homegrown feature flagging system that uses YML files to drive a Client-specific configuration. When we build a docker image for a particular Client, that Client’s configuration is used as the application configuration.

### Environment Variables

Because values in the Resource Registry cannot change without a redeploy of the entire application codebase, we have added a layer of indirection using Environment Variables. These variables are used in place of a hard-coded configuration value and point at values that only exist in the environment. These variables have their values set in the Kubernetes repository specific to each Client.

What this extra layer of indirection allows us to do is change Client configuration without redeploying the application, as well as having specific features turned on in environments where they need to be tested.

For all new features that are developed, we require a Feature Flag to control the visibility to our end users. All Pull Requests will require reference to this feature flag to ensure that no new development is unflagged and `trunk` remains safe and stable.
