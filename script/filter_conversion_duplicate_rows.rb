def filter_duplicate_rows(file)
  @spreadsheet = Roo::Spreadsheet.open(file)
  o_stream = File.open(File.join(Rails.root, "conversion_employees", "Filtered_" + File.basename(file)), 'wb')
  @out_csv = CSV.new(o_stream)

  ssns = (2..@spreadsheet.last_row).inject([]) do |ssns, idx|
    row = @spreadsheet.row(idx)
    row[2].downcase == 'delete' ? ssns : (ssns << row[19])
  end

  ssns.uniq.each do |ssn|
    matched = []
    (2..@spreadsheet.last_row).each do |idx|
      row = @spreadsheet.row(idx)
      next if row[2].downcase == 'delete'
      if row[19] == ssn
        matched << row
      end
    end
    select_most_recent_row(matched)
  end

  @out_csv.close
end

def select_most_recent_row(matched)
  matched.uniq!
  if matched.size > 1
    matched.sort{|row1, row2| DateTime.parse(row1[0]) <=> DateTime.parse(row2[0])}
    if matched[-1][0] == matched[-2][0]
      puts "Found more than 1 row for given file date ---#{matched[-1][19]}--#{matched.map{|x| x[0]}}--#{matched.map{|x| x[2]}}"
    else
      puts "Found---#{matched[-1][19]}--#{matched.map{|x| x[0]}}--and picked---#{matched[-1][0]}"
      @out_csv << matched.pop
    end
  else
    @out_csv << matched.pop
  end
end

dir_glob = File.join(Rails.root, "conversion_employees", "*.{xlsx,csv}")
Dir.glob(dir_glob).each do |file|
  filter_duplicate_rows(file)
end
