# CI Tools for Maximizing Concurrency on Cucumbers and Rspec

Running `rspec` or `cucumber` locally will run these tests sequentially. When integrating code into `trunk` we use GitHub Actions (GHA) to run these test suites. One very helpful thing GHA provides is job concurrency. Unfortunately, we don't get this for free. There is no flag that's passed to the cucumber or rspec binaries that automatically split up tests.

## Test Boosters

A gem was found some time ago called [Test Boosters](https://github.com/renderedtext/test-boosters) that accelerates the process of parallelizing our tests. This repo _was found to contain malicious code_ and so @TreyE [forked the repo](https://github.com/treye/test-boosters).

The gem provides a standardized way of splitting tests up by using a "split config" json file that follows the shape:
```json
[
  { "files": ["spec/a_spec.rb", "spec/d_spec.rb"] }
  { "files": ["spec/b_spec.rb"] }
  { "files": ["spec/c_spec.rb"] }
]
```
Each one of the `{ "files": [] }` is then available as a `job` when passed to the booster gem, e.g. `rspec_booster --job 1/3` would be evaluated as `bundle exec rspec spec/a_spec.rb spec/d_spec.rb`

## Creating the Split Configuration Files

The process to create the split configuration files is as follows:
1. Run tests sequentially, outputting the results to a json file.
2. Run script to evaluate test output, producing an optimized split.


## Rspec Test Output
The goal of running tests sequentially is to produce a json file (native to the rspec runner) that includes _runtime information_ for each spec. For `rspec`, simply running `bundle exec rspec --format json --out rspec-report.json` will produce a json file with the following shape:
``` ts
interface RspecReport {
  version: string;
  examples: RspecExample[];
  summary: RspecSummary;
  summary_line: string;
}

interface RspecExample {
  id: string;
  description: string;
  full_description: string;
  status: string;
  file_path: string;
  line_number: string;
  run_time: number;
  pending_message: any;
}

interface RspecSummary {
  duration: number;
  example_count: number;
  failure_count: number;
  pending_count: number;
  errors_outside_of_examples_count: number;
}

```

### Rspec Split Configuration

After this test has been run successfully and the json file has been created, we need to run this file through a script that will evaluate the run times and produce a split configuration that optimizes the split of files.

`rspec-split.ts` is the file that contains the logic to process the test output json and turn it into a split configuration. This file is used by running `npx ts-node ci/scripts/rspec-split <reportPath> <splitConfigPath> <manualGroupCount>`

`reportPath`: where the current test output json file is located

`splitConfigPath`: where the split configuration file should be written

`manualGroupCount`: this number is optional and will be automatically set by the script



