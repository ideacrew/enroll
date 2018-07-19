require 'csv'

namespace :reports do
  namespace :shop do

    desc "All Organizations"
    task :organizations_with_matching_name_or_address => :environment do
      include Config::AcaHelper

      field_names  = %w(
        LegalName
        DBA
        Address1
        Fein
        SimilarField
        )

      attributes_to_look_for = ["legal_name", "dba", "address_1"]

      processed_count = 0
      file_name = "#{Rails.root}/list_of_orgs_with_matching_field_values_#{TimeKeeper.date_of_record.strftime('%Y-%m-%d')}.csv"

      CSV.open(file_name, "w", force_quotes: true) do |csv|
        csv << field_names
        attributes_to_look_for.each do |attribute|
          begin
            organizations = find_organizations_by_attribute(attribute)
            organizations.each do |organization|
              primary_address_1 = organization.profiles.first.primary_office_location.address.address_1 rescue nil
              csv << [
                organization.legal_name,
                organization.dba,
                primary_address_1,
                organization.fein,
                attribute
              ]
              processed_count += 1
            end
          rescue => e
            puts "Error: #{e.backtrace}" unless Rails.env.test?
          end
        end
      end

      puts "Report of all the organizations with common field_names: #{field_names}, Organizations to output file: #{file_name}" unless Rails.env.test?
    end

    def find_organizations_by_attribute(attribute)
      case attribute
      when "legal_name"
        organization_legal_names = BenefitSponsors::Organizations::Organization.all.map(&:legal_name).uniq
        organization_legal_names.compact!
        organization_legal_names.delete("")
        organizations = organization_legal_names.inject([]) do |array, legal_name|
          legal_name = legal_name.gsub(/[^0-9a-z ]/i, '')
          orgs = BenefitSponsors::Organizations::Organization.all.where(legal_name: /#{legal_name}/i)
          array << orgs if orgs.count > 1
          array.compact
          array.flatten
        end
        organizations.uniq
      when "dba"
        organization_dbas = BenefitSponsors::Organizations::Organization.all.map(&:dba).uniq
        organization_dbas.compact!
        organization_dbas.delete("")
        organization_dbas.delete(" ")
        organizations = []
        organization_dbas.each do |dba|
          actual_dba = dba
          dba = dba.gsub(/[^0-9a-z ]/i, '')
          if dba.present?
            dba = /#{dba}/i rescue ""
            next if dba.blank?
            orgs = BenefitSponsors::Organizations::Organization.all.where(dba: dba)
            organizations << orgs if orgs.count > 1
            organizations.compact
            organizations.flatten
          end
        end
        organizations.uniq
      when "address_1"
        organization_primary_address1s = BenefitSponsors::Organizations::Organization.all.flat_map(&:profiles).map(&:primary_office_location).map(&:address).map(&:address_1).uniq
        organization_primary_address1s.compact!
        organization_primary_address1s.delete("")
        organizations = organization_primary_address1s.inject([]) do |array, address1|
          orgs = BenefitSponsors::Organizations::Organization.all.where(:"profiles.office_locations.is_primary" => true).where(:"profiles.office_locations.address.address_1" => /#{address1}/i)
          array << orgs if orgs.count > 1
          array.compact
          array.flatten
        end
        organizations.uniq
      end
    end
  end
end
