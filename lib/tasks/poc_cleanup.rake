namespace :employers do
  desc "cache premiums plan for fast group fetch"
  task :poc_cleanup => :environment do 
    orgs = Organization.no_timeout.where({
      "employer_profile.profile_source" => "conversion",
      "employer_profile.plan_years.start_on" => Date.new(2015, 7, 1)
    })
    emps = orgs.map(&:employer_profile);nil

    braced_staff = emps.map{ |e| e.staff_roles.map{ |p| [e.fein,p] } };nil
    staff = braced_staff.map{|item| item[0]};nil

    fixme = []
    staff.each do |item| 
      fein=item[0]
      person=item[1]
      census_employees=CensusEmployee.where(first_name: person.first_name, last_name: person.last_name)
      duplicates = Person.where(first_name: person.first_name, last_name: person.last_name).count
      census_employees.each do |ce|

        ep =  EmployerProfile.find(ce.employer_profile_id)
        if(ep && (ep.fein ==fein))
          employee_role = Person.where('employee_roles.census_employee_id': ce.id).count
          puts "#{fein}, person.user #{item[1].user_id || 'No user id provided ..'} for #{ce.employee_role_id || 'no census employee role id'}, Census Employee #{ce.id} Role via person #{employee_role}.   duplicates #{duplicates}"
          fixme << (item + [ce, ce.id])
        end
      end
    end;nil

    fixme_dups = fixme.select do |item|
      fein= item[0]
      person= item[1]
      ce = item[2]
      duplicates = Person.where(first_name: person.first_name, last_name: person.last_name).count
      puts "missing employee_role_id for ce #{ce.id} #{ce.first_name} #{ce.last_name} FEIN #{item[0]}" if !ce.employee_role_id
      if duplicates < 2 || !ce.employee_role_id  
        puts "Not fixing for for #{fein},  #{person.first_name}, #{person.last_name}, census_employee: #{ce.id}, ce.employee_role_id #{ce.employee_role_id || ' no employee_role id    '}, duplicates #{duplicates}" 
      end
      duplicates > 1  && ce.employee_role_id
    end;nil

    puts fixme_dups.count

    def count_roles person
      roles = person.consumer_role ? 1 : 0
      roles += person.employee_roles.count + person.employer_staff_roles.count 
      roles += person.broker_role ? 1 : 0
      roles
    end 

    def consolidate person1, person2, employer_profile_id
      if person1.id == person2.id
        puts "No migration needed persons are the same #{person1.id}"
        return
      end
      if person1.user_id && person2.user_id
        puts "User has already established separate users for #{person1.id} and #{person2.id} #{person1.first_name} #{person1.last_name}"
        return
      end
      email = person1.emails.first	
      phone = person1.phones.first
      user = person1.user
      if user
        person1.unset(:user_id)
        user.unset(:person_id)
        person2.user = user
        person2.save!
        puts "User id #{user.id} moved from person1 #{person1.id} to #{person2.id} #{Person.find(person2.id).user}"
        user.roles = (user.roles << 'employee')
        user.save!
        puts "Roles #{user.roles} for #{user.id}"
      end
      person2.emails = (person2.emails << email) if email
      person2.save!
      person2.phones = (person2.phones << phone) if phone
      person2.save!
      EmployerStaffRole.create(person: person2, employer_profile_id: employer_profile_id)
      person1.delete
      puts "here migrated #{person1.id}, which had role count #{count_roles person1}  to #{person2.id} employer profile #{employer_profile_id}  #{email}, #{phone}"
    end

    fixme_dups.each{|item| 
      fein = item[0]
      person1 = item[1]
      ce = item[2]
      employee_role_id = ce.employee_role_id
      if employee_role_id
        person2 = EmployeeRole.find(employee_role_id).person
        consolidate person1, person2, item[2].employer_profile_id
        puts "FEIN #{fein} #{Organization.where(fein: fein).first.legal_name}"
      else
        puts "missing employee_role_id for ce #{ce.id} #{ce.first_name} #{ce.last_name} FEIN #{item[0]}"
      end
    };nil
 
  end
end
