require 'csv'

namespace :reports do
  namespace :shop do

    desc "Identify employer's account information"
    task :employer_information_dc => :environment do
      begin
        csv = CSV.open('NFP_SampleERInfo.csv',"r",:headers =>true, :encoding => 'ISO-8859-1')
        @data= csv.to_a
        miss_match = CSV.open('miss_match_nfp_file.csv',"w",:headers =>true, :encoding => 'ISO-8859-1')
        @data.each do |data_row|
          organization = Organization.where(:hbx_id => data_row["CUSTOMER_CODE"]).first
          if organization.nil? || 
            organization.fein != data_row["TAX_ID"] ||
            organization.dba != data_row["CUSTOMER_NAME"]||
            organization.primary_office_location.address.try(:address_1) !=data_row["B_ADD1"]||
            organization.primary_office_location.address.try(:address_2) !=data_row["B_ADD2"]
            miss_match << data_row 
          end
        end
      rescue Exception => e
        puts "Unable to open file #{e}"
      end 
    end
  end
end