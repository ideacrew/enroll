require 'tasks/iam_black_list/black_list'

namespace :import do

  desc "Import iam blacklist "
  task :iam_black_list => :environment do
    files = Dir.glob(File.join(Rails.root, "db/seedfiles", "IAM_BLACKLIST.xlsx"))
    blacklist_items = []
    if files.present?
      puts files
      result = Roo::Spreadsheet.open(files.first)
      sheet_data = result.sheet("List")
      2.upto(sheet_data.last_row) do |row_number|
        blacklist_items << BlackList.from_row(sheet_data.row(row_number))
      end
      blacklist_items.each do |item|
        item.update_or_create_curam_user
      end
    end
  end


end
