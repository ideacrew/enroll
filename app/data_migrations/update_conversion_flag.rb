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
        emp = organization.first.employer_profile
        
        if ENV['profile_source'] == "self_serve"
          attestation_doc(emp)
        else
          emp.update_attributes!(profile_source: ENV['profile_source'])
          puts "Conversion flag updated #{ENV['profile_source']} for #{fein}" unless Rails.env.test?
          attestation_doc(emp)
        end
      end
    rescue Exception => e
      puts e.message
    end
  end

  def attestation_doc(employer)
    attestation = employer.employer_attestation.blank?  ? employer.build_employer_attestation : employer.employer_attestation
    attestation.submit! if attestation.may_submit?
    attestation.approve! if attestation.may_approve?
    attestation.save
    puts "Employer Attestation approved" unless Rails.env.test?
  end
end
