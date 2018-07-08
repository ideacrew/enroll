namespace :cca do
  desc "Restore HbxId for MPYC Employers"
  task :restore_hbx_id_for_mpyc_employers => :environment do
    file_path = File.join(Rails.root, 'db', 'seedfiles', "mpyc_employers.csv")

    file = Roo::Spreadsheet.open(file_path)
    sheet = file.sheet(0)
    columns = sheet.row(1)

    puts "*** Started restoring HBX ID  for existing MPYC Employers ****"

    def sanitize(val)
      return nil if val.blank?
      val.to_s.split(".")[0].strip.rjust(9, '0')
    end

    (2..sheet.last_row).each do |key|
      row = Hash[[columns, sheet.row(key)].transpose]
      fein = sanitize(row["FEIN"])
      restorable_hbx_id = sanitize(row["Organization assigned hbx_id"])
      next if restorable_hbx_id.blank?
      sponsors = ::BenefitSponsors::Organizations::Organization.all.employer_profiles.where(fein: fein)
      if sponsors.blank? || sponsors.size != 1
        puts "FAILURE: Found No/More than 1 organization with FEIN: #{fein}."
        next
      end

      sponsor = sponsors.first
      prev_hbx_id = sponsor.hbx_id

      sponsor.assign_attributes(hbx_id: restorable_hbx_id)
      if sponsor.save
        puts "SUCCESS: Restored ER Hbx Id from #{prev_hbx_id} to #{restorable_hbx_id} for ER with FEIN - #{fein}, legal name - #{sponsor.legal_name}"
      else
        puts "FAILURE: HBX ID Restore failed for ER FEIN - #{fein}"
      end
    end

    puts "***** Finished Updating sponsor Hbx Id's ***"
  end
end
