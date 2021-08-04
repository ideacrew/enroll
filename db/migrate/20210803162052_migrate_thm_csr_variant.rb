# frozen_string_literal: true

# RAILS_ENV=production bundle exec rails db:migrate:up VERSION="20210803162052"
# rubocop:disable Metrics/CyclomaticComplexity
class MigrateThmCsrVariant < Mongoid::Migration
  def self.up
    @logger = Logger.new("#{Rails.root}/log/migrate_thm_csr_variant.log") unless Rails.env.test?
    @logger.info "Script Start - #{TimeKeeper.datetime_of_record}" unless Rails.env.test?
    people = Person.all
    people.each do |person|
      if person.primary_family.nil? || person.primary_family.active_household.nil? || person.primary_family.active_household.latest_active_tax_household.nil?
        puts "No primary_family or active househod or latest_active_household exists for person with the given hbx_id #{person.hbx_id}" unless Rails.env.test?
        next
      end
      active_household = person.primary_family.active_household
      latest_tax_household = active_household.latest_active_tax_household_with_year(TimeKeeper.date_of_record.year)
      if latest_tax_household.present? && latest_tax_household.latest_eligibility_determination.present?
        ed = latest_tax_household.latest_eligibility_determination
        csr_percent = ed.csr_percent_as_integer
        thhm = latest_tax_household.tax_household_members.where(is_ia_eligible: true)
        if thhm.present?
          thhm.each do |thm|
            thm.update(csr_percent_as_integer: csr_percent)
          end
        end
      end
      puts "Update eligibility_determinations for tax household members with the given hbx_id #{person.hbx_id}" unless Rails.env.test?
      @logger.info "End of the script" unless Rails.env.test?
    end
  end
# rubocop:enable Metrics/CyclomaticComplexity

  def self.down; end
end