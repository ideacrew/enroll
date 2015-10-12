require 'csv'

def update_employer_info(row_hash)
  fein = row_hash["fein"]
  hbx_id = row_hash["hbx_id"]
  employer_org = Organization.where(fein: fein).first
  props = { }
  if employer_org.nil?
    puts "Cound not find profile for FEIN #{fein}"
  else
    if !hbx_id.blank?
      employer_org.update_attributes!({:hbx_id => hbx_id})
      employer_org = Organization.where(fein: fein).first
    end
    if !row_hash["street_1"].blank?
      first_office = employer_org.office_locations.detect(&:is_primary?)
      if first_office.nil?
        puts "Cound not find primary office for FEIN #{fein}"
      else
        address_attrs = {
          :address_1 => row_hash["street_1"],
          :state => row_hash["state"],
          :city => row_hash["city"],
          :zip => row_hash["zip"]
        }
        if !row_hash["street_2"].blank?
          address_attrs["address_2"] = row_hash["street_2"]
        end
        if !row_hash["street_3"].blank?
          address_attrs["address_3"] = row_hash["street_3"]
        end
        if !first_office.address.update_attributes(address_attrs)
          puts "Cound not update primary office for FEIN #{fein}\n  with values: #{address_attrs.inspect}"
        end
      end
    end
  end
end


CSV.foreach("employer_info.csv", :headers => true) do |row|
  update_employer_info(row.to_hash)
end
