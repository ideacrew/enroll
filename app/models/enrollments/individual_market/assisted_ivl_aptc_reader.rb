class Enrollments::IndividualMarket::AssistedIvlAptcReader
  require 'csv'

  attr_reader :assisted_individuals, :all_assisted_individuals
  attr_accessor :calender_year

  def all_hbx_ids
    file_name = "#{Rails.root}/public/#{TimeKeeper.date_of_record.year + 1}_FA_Renewals.csv"
    @all_assisted_individuals = {}

    CSV.foreach(file_name, headers: true, header_converters: :symbol) do |row|
      row_hash = row.to_hash

      if row_hash[:ssn].present? && row_hash[:ssn] != '#N/A' && row_hash[:ssn] != "0"
        person = Person.by_ssn(row_hash[:ssn]).first
      end

      if person.blank? && row_hash[:hbx_id].present?
        person = Person.by_hbx_id(row_hash[:hbx_id]).first
      end

      if person.blank?
        family = Family.where(:e_case_id => /#{row_hash[:icacaseref]}/i).first
        person = family.primary_applicant.person if family.present?
      end

      next if person.blank?

      @all_assisted_individuals[person.hbx_id] = {
        applied_percentage: row_hash[:applied_pct], 
        applied_aptc: row_hash[:"#{calender_year}_applied"], 
        csr_amt: row_hash[:"#{calender_year}_csr"]
      }
    end
  end

  def call
    file_name = "#{Rails.root}/pids/2018_FA_Renewals.csv"
    @assisted_individuals = {}

    CSV.foreach(file_name, headers: true, header_converters: :symbol) do |row|
      row_hash = row.to_hash

      next if row_hash[:error_message].to_s.strip == "CURAM, NOT EA"

      if ["EA, NOT CURAM", "CURAM ERROR"].include?(row_hash[:error_message].to_s.strip)
        row_hash[:"#{calender_year}_applied"] = "0"
        row_hash[:"#{calender_year}_csr"] = "0"
      end
     
      @assisted_individuals[row_hash[:subscriber]] = {
        applied_percentage: row_hash[:applied_pct], 
        applied_aptc: row_hash[:"#{calender_year}_applied"], 
        csr_amt: row_hash[:"#{calender_year}_csr"],
        max_aptc: row_hash[:"#{calender_year}_aptc"]
      }
    end
  end
end
