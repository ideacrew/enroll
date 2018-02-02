require File.join(Rails.root, "lib/mongoid_migration_task")

class UpdateConversionFlag < MongoidMigrationTask
  def migrate
    begin
      feins = ENV['fein'].split(',').map(&:lstrip)
      feins.each do |fein|
      organization = Organization.where(fein: fein)
      if organization.size != 1
        puts "Issues with organization of fein #{fein}" unless Rails.env.test?
        next
      end
      organization.first.employer_profile.update_attributes!(profile_source: ENV['profile_source'])
      puts "Conversion flag updated #{ENV['profile_source']} for #{fein}" unless Rails.env.test?
      return unless ENV['profile_source'] == "conversion"
      emp = organization.first.employer_profile
      attestation = emp.employer_attestation.blank?  ? emp.build_employer_attestation : emp.employer_attestation
      attestation.submit! if attestation.may_submit?
      attestation.approve! if attestation.may_approve?
      attestation.save
      puts "Employer Attestation approved for #{fein}" unless Rails.env.test?
      end
    rescue
      puts "Bad Employer Record" unless Rails.env.test?
    end
  end
end
