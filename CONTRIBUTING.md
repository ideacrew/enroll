# Contributing to Enroll

We would love for you to contribute to Enroll and help make it even better than it is today! As a contributor, here are the guidelines we would like you to follow:

 - [Submission Guidelines](#submit)
 - [Commit Message Guidelines](#commit)

## <a name="submit"></a> Submission Guidelines

### Submitting a Pull Request (PR)

Before you submit your Pull Request (PR) consider the following guidelines:

1. [Fork](https://docs.github.com/en/get-started/quickstart/fork-a-repo) the `ideacrew/enroll` repo
2. In your forked repository, make your changes in a new git branch
3. Create your patch, **including appropriate test cases**
4. Follow our [Development Process](DEVELOPMENT.md)
5. Run the most relevant tests, including any that you've updated or created, and ensure that all tests pass
6. Commit your changes using a descriptive commit message
7. Push your branch to GitHub
8. In GitHub, send a pull request to `ideacrew:trunk`

### Reviewing a Pull Request

Once submitted, IdeaCrew will assign two team members to review the proposed changes.

#### Addressing review feedback

If we ask for changes via code reviews then:

1. Make the required updates to the code
2. Re-run the test suites to ensure tests are still passing
3. Push additional commit(s)

## <a name="commit"></a> Commit Message & PR Title Guidelines

At IdeaCrew, we squash all PRs into a single commit that uses the PR title as the commit message. Because of this, individual commit messages are less important than the PR title. All PR titles must follow a few simple rules:

1. Should not reference any ticket #
2. Should be ~50 characters or less in length
3. Should be in present tense ("change", not "changed" or "changes")
4. No capitalization
5. No punctuation

## After your pull request is merged

After your pull request is merged, you can safely delete your branch and pull the changes from the main (upstream) repository
