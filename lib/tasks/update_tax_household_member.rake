#This rake task will update thhm with the given is_ia_eligible and is_medicaid_chip_eligible.
#RAILS_ENV=production bundle exec rake task:thhm:update_thhm primary_hbx_id=12345 is_ia_eligible=false is_medicaid_chip_eligible=true dependent_hbx_id=132445
#primary_hbx_id and dependent_hbx_id can be same.
#Run this rake task after executing this rake create_tax_household with the appropriate fields.

namespace :task do
  namespace :thhm do
    desc "Update tax household member"
    task :update_thhm => :environment do

      dependent_hbx_id = ENV['dependent_hbx_id'].to_s
      is_ia_eligible = ENV['is_ia_eligible']
      is_medicaid_chip_eligible = ENV['is_medicaid_chip_eligible']
      primary_hbx_id = ENV['primary_hbx_id'].to_s

      if !(is_ia_eligible == "true" && is_medicaid_chip_eligible == "true")
        person = Person.by_hbx_id(primary_hbx_id).first rescue nil
        dependent = Person.by_hbx_id(dependent_hbx_id).first rescue nil

        if person.present? && dependent.present?
          if person.primary_family.present?
          primary_family = person.primary_family
          family_member = primary_family.family_members.where(person_id: dependent.id).first
          family_member_id = family_member.id if family_member.present?
          active_household = primary_family.active_household
          latest_active_thh = active_household.latest_active_thh
          latest_active_thh.update_thhm(is_ia_eligible, is_medicaid_chip_eligible, family_member_id) if latest_active_thh.present?
          puts "THHM updated successfully" unless Rails.env.test?
          else
            puts "primary_hbx_id do not have primary family" unless Rails.env.test?
          end
        else
          puts "No Person Record Found for given HBX_IDs, Please check the HBX_IDs" unless Rails.env.test?
        end
      else
        puts "Person cannot have both eligibilities true " unless Rails.env.test?
      end
    end
  end
end