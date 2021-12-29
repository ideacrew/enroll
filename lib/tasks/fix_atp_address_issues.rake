# Migration for fixing account transferred in address issues

# Run this with RAILS_ENV=production bundle exec rake migrations:fix_atp_address_issues
# To run for a single FAA only: RAILS_ENV=production bundle exec rake migrations:fix_atp_address_issues app="HBX_ID"
# To run just a report: RAILS_ENV=production bundle exec rake migrations:fix_atp_address_issues report_only=true
namespace :migrations do
  desc "Fix ATP Address Issues"
  task :fix_atp_address_issues, [:file] => :environment do |task, args|
    # find applications transferred in
    # update is_homeless for people and applicants
    # update duplicate home/mailing addresses for people and applicants
    # update same_as_primary for applicants

    @target_app = if ENV['app'].present?
                  FinancialAssistance::Application.where(hbx_id: ENV['app'])
                 else 
                  FinancialAssistance::Application.draft.where(:transfer_id.nin => [nil, ''])
                 end

    @compare_keys = ["address_1", "address_2", "city", "state", "zip"]

    def matching_address(person)
      mailing = person&.addresses&.detect {|a| a.kind == "mailing" }
      home = person&.addresses&.detect {|a| a.kind == "home" }
      return false unless mailing && home
      mailing.attributes&.select {|k, _v| @compare_keys.include? k} == home&.attributes&.select do |k, _v|
                                                                      @compare_keys.include? k
                                                                    end
    end

    def same_address_with_primary(member, primary)
      sas = member.is_temporarily_out_of_state? == primary.is_temporarily_out_of_state? &&
            member&.home_address&.attributes&.select {|k, _v| @compare_keys.include? k} == primary&.home_address&.attributes&.select do |k, _v|
                                                                                            @compare_keys.include? k
                                                                                          end
    end

    @people = Person.where(:hbx_id.in => @target_app.distinct('applicants.person_hbx_id'))
    return unless @people
    def pull_fixes
      puts("Beginning getting addresses")
      file_name = "#{Rails.root}/list_address_fixes.csv"
      total_count = @people.count
      users_per_iteration = 10_000.0
      counter = 0
      number_of_iterations = (total_count / users_per_iteration).ceil
      CSV.open(file_name, 'w+', headers: true) do |csv|
        csv << ["person_hbx_id", "isnt_homeless", "dup_addresses"]
        while counter < number_of_iterations
          offset_count = users_per_iteration * counter
          output = @people.no_timeout.offset(offset_count).each do |person|
            isnt_homeless = person.is_homeless? == true && person.addresses&.detect {|a| a.kind == "home" }
            mailing = person.addresses.detect {|a| a.kind == "mailing" }
            unless mailing.nil?
              updated_address_hash = person.addresses.reject { |a| a[:kind] =="mailing" } if matching_address(person)
            end
            addresses = mailing.present? && updated_address_hash != person.addresses
            csv << [person.hbx_id, isnt_homeless, addresses] if isnt_homeless || addresses
            counter += 1
          end
        end
      end
    end
    pull_fixes

    def update_addresses
      puts("Beginning fixing addresses")
      Person.skip_callback(:update, :after, :person_create_or_update_handler)
      file_name = "#{Rails.root}/update_address_fixes.csv"
      CSV.open(file_name, 'w+', headers: true) do |csv|
        csv << ["person_hbx_id", "comments"]
        output = @people.no_timeout.each do |person|
          puts "Examining Person: #{person.hbx_id} #{person.full_name}"
          counters = {}
          counters[:person] = { fixed: 0, homeless_fix: 0, address_fix: 0, no_fix_needed: 0 }
          isnt_homeless = person.is_homeless? == true && person.addresses&.detect {|a| a.kind == "home" }
          counters[:person][:homeless_fix] += 1 if isnt_homeless
          mailing = person.addresses.detect {|a| a.kind == "mailing" }
          unless mailing.nil?
            updated_address_hash = person.addresses.reject { |a| a[:kind] =="mailing" } if matching_address(person)
          end
          addresses = mailing.present? && updated_address_hash != person.addresses
          counters[:person][:address_fix] += 1 if addresses
          if addresses || isnt_homeless
            person.is_homeless = false if isnt_homeless
            person.addresses = updated_address_hash if addresses
            person.save!
            counters[:person][:fixed] += 1
          else
            counters[:person][:no_fix_needed] += 1
          end

          counters[:faa_apps] = { fixed: 0, homeless_fix: 0, address_fix: 0, same_as_primary_fix: 0, no_fix_needed: 0 }

          @target_app.select{|application| application.applicants.detect{|a| a.person_hbx_id == person.hbx_id}}&.each do |application|
            primary = application.primary_applicant
            application.applicants&.select{|a| a.person_hbx_id == person.hbx_id}.each do |applicant|
              next if applicant.nil?
              a_isnt_homeless = applicant.is_homeless? == true && applicant.addresses.any?
              counters[:faa_apps][:homeless_fix] += 1 if a_isnt_homeless
              a_mailing = applicant.addresses&.detect {|a| a.kind == "mailing" }
              unless a_mailing.nil?
                a_updated_address_hash = applicant.addresses.reject { |a| a[:kind] =="mailing" } if matching_address(applicant)
              end
              a_addresses = a_mailing.present? && a_updated_address_hash != applicant.addresses
              counters[:faa_apps][:address_fix] += 1 if a_addresses
              same_as_primary = same_address_with_primary(applicant, primary)
              a_same_as_primary = same_as_primary != applicant.same_with_primary
              counters[:faa_apps][:same_as_primary_fix] += 1 if a_same_as_primary
              if a_addresses || a_isnt_homeless || a_same_as_primary
                applicant.is_homeless = false if a_isnt_homeless
                applicant.addresses = a_updated_address_hash if a_addresses
                applicant.save!
                counters[:faa_apps][:fixed] += 1
              else
                counters[:faa_apps][:no_fix_needed] += 1
              end
              applicant.set(same_with_primary: same_as_primary) if a_same_as_primary
            end
            application.save!
          end
          csv_comment = counters.to_s.gsub!(",", "")
          csv << [person.hbx_id, csv_comment]
        end
      end
      Person.set_callback(:update, :after, :person_create_or_update_handler)
    end
    update_addresses unless ENV['report_only'].present?
  end
end





