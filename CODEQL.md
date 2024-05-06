# CodeQL Implementation and Security Usage

CodeQL is used to perform security checks, and to enforce them as github actions.

## Automatic Enforcement in Github Actions

We currently do not use the full suite of Ruby checks, in the automated actions, but opt in incrementally once we fix a particular set of issues to prevent new issues of the given type from being introduced.  This allows us to incrementally improve our code without having long-standing broken branches - which would be required if we tried to fix all issues simultaneously.

The resulting reports are then run through a summary analyzer to produce a quick/pass fail and issue count without exposing the details of the potential issues or vulnerabilites as public repository artifacts.

If you desire to see exactly what the issues are see "Running CodeQL Locally" below.

## Running CodeQL Locally

These reports are intended to be run locally on the developers machine, **not** in a docker image.  They do not require installation of Ruby or any gems.  You do **not** need to be able to execute the Enroll application or its specs in order to run CodeQL.

A detailed CodeQL report, using the same logic as the github actions run, can be produced locally by following these steps:
1. First, install CodeQL (in the case of most developers this can be done with `brew install codeql`).
2. Secondly, from the project directory, execute `codeql_report.sh`.

## CodeQL Execution Configuration

The configuration and scripts we use to run and extract machine and human-readable CodeQL reports exist in the following locations:
1. `codeql.yml` - contains general CodeQL configuration
2. `codeql_report.sh` - an all-in-one script to build the CodeQL database and produce a rich report, will open your web browser to the report once completed.
3. `codeql/` contains various elements for configuring and executing CodeQL reports:
   1. `*.sh` files are convenience scripts for executing various steps of the analysis process.  Of particular importance is `create_codeql_report.sh`, which lists the CodeQL rules we currently run for our github action.
   2. The `*.ql` files represent custom queries we either use or plan to use in the future.
   3. `qlpack.yml` - configuration and dependency information for our CodeQL suite runs - primarily indicates which packs are needed for queries to execute.
   4. `sarif_reporter` - a simple javascript tool which reads the report output, produces a count, and returns non-zero if there are errors.  This tool is used by the github action to both analyze the report and avoid printing the results to the console or a series of public artifacts.
   5. `sarif_html_report` - a simple react application which provides an html formatted report of the issues found by CodeQL.  Used by local reporting to help developers locate the issues.