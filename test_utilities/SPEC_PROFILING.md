# RSpec Profiling

This file explains the steps to record RSpec test runtimes, group them properly, and commit the updated data to be used by others.

## Record the spec timings

Add the following line to your `.rspec_parallel` file:
> --format ParallelTests::RSpec::RuntimeLogger --out tmp/parallel_runtime_rspec.log

Run rspec to collect the timing data:
> bundle exec rake parallel:spec[1]

It is mandatory that this be run with one processor to get exact timings, and that you use the parallel runner.  Adding the formatter to regular rspec and running it will not produce any data.  Running with more than one process will produce incorrect data.

## Review and Reformat the Output

Run the following to produce a new, correctly grouped file:
> ruby test_utilities/resort_test_runtimes.rb

This will create a file called `resorted_times.log`

Feel free to view the `resorted_times.log` file and inspect the output.
You can also run the following command to see how the timings from the new file would break down among a 3 process parallel run:
> ruby test_utilities/split_test_runtimes.rb

## Replace the Old Data

Once comfortable with the output, you can replace the old data file:
> cp -f resorted_times.log tmp/parallel_runtime_rspec.log

Feel free to then commit this updated file.  It will then be used as timing data for others.

## Clean Up

Don't forget to remove the line you added to `.rspec_parallel`.  If kept there, when **you** try to run the specs in parallel it will incorrectly overwrite your timing data.