#This rake task will update the eligibility kinds (is_ia_eligible and is_medicaid_chip_eligible) of a thhm.
#RAILS_ENV=production bundle exec rake task:thhm:update_eligibility_kinds primary_hbx_id=12345 dependent_hbx_id=132445 eligibility_kinds=is_ia_eligible:true,is_medicaid_chip_eligible:false
#primary_hbx_id and dependent_hbx_id can be same, in case you are updating for the primary.
#Run this rake task after executing this rake create_tax_household with the appropriate fields.

namespace :task do
  namespace :thhm do
    desc "Update tax household member's eligibility kinds"
    task :update_eligibility_kinds => :environment do

      dependent_hbx_id = ENV['dependent_hbx_id'].to_s
      is_ia_eligible = ENV['is_ia_eligible']
      is_medicaid_chip_eligible = ENV['is_medicaid_chip_eligible']
      primary_hbx_id = ENV['primary_hbx_id'].to_s
      options = ENV['eligibility_kinds']

      eligibility_kinds_hash = {}
      options.split(",").each do |option|
        key = eligibility_kind_type = option.split(":").first
        val = eligibility_kind_val = option.split(":").second
        eligibility_kinds_hash [key] = val
      end

      person = Person.by_hbx_id(primary_hbx_id).first rescue nil
      dependent = Person.by_hbx_id(dependent_hbx_id).first rescue nil

      if person.present? && dependent.present?
        if person.primary_family.present?
        primary_family = person.primary_family
        family_member = primary_family.family_members.where(person_id: dependent.id).first
        family_member_id = family_member.id if family_member.present?

        active_household = primary_family.active_household
        latest_active_thh = active_household.latest_active_thh
        tax_household_member = latest_active_thh.tax_household_members.where(applicant_id: family_member.id).first
        tax_household_member.update_eligibility_kinds(eligibility_kinds_hash) if latest_active_thh.present?

        puts "Eligibilitiy Kinds for THHM updated successfully" unless Rails.env.test?
        else
          puts "No Primary family for the supplied Primary HBX ID" unless Rails.env.test?
        end
      else
        puts "Person or Dependent not found." unless Rails.env.test?
      end
    end
  end
end