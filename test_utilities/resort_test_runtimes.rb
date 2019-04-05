# Create a file called "resorted_times.log" from the output of rspec parallel
# timing data.  This will place the file in the root directory.
#
# This file will now contain the test runtimes properly re-grouped in the same
# way that the parallel tests gem expects them as input.
#
# You can examine what the new breakdowns of time are by using the
# "split_test_runtimes.rb" script.
#
# When finished, you will want to copy and commit the contents of the new
# "resorted_times.log" file over the current "tmp/parallel_runtime_rspec.log"
# file.

file_lines = File.read(File.join(File.dirname(__FILE__), "..", "tmp/parallel_runtime_rspec.log"))

timed_lines = file_lines.split("\n").map do |f_line|
  name, time_str = f_line.split(":")
  [time_str.to_f, name]
end

clean_timed_lines = Array.new
component_times = Hash.new { |h, k| h[k] = 0.0 }

timed_lines.each do |tl|
  if tl.last.start_with?("components")
    components, engine, *rest = tl.last.split("/")
    component_times["spec/components/#{engine}_spec.rb"] = component_times["spec/components/#{engine}_spec.rb"] + tl.first
  else
    clean_timed_lines << tl
  end
end

component_times.each_pair do |k, v|
  clean_timed_lines << [v, k]
end

File.open(File.join(File.dirname(__FILE__), "../resorted_times.log"), 'w') do |f|
  clean_timed_lines.sort_by(&:first).reverse.each do |tl|
    f.puts(tl.reverse.join(":"))
  end
end
