namespace :role do
  desc "remove assister and cac roles from users"
  # Usage rake role:remove
  task :remove => [:environment] do

    CSV.foreach("bad_users.csv") do |row|
      email = row[2]
      role = row[3]
      hbx = row[4]

      if hbx.present?
        person = Person.where(hbx_id:hbx).first
        if person.present?
          case role
          when "assister"
            if person.assister_role.present?
              person.assister_role.destroy
              person.update(is_disabled:true)
            else
              puts "Person #{person.full_name} nolonger has #{role}"
            end
          when "cac"
            if person.csr_role.present?
              person.csr_role.destroy
              person.update(is_disabled:true)
            else
              puts "Person #{person.full_name} nolonger has #{role}"
            end
          end
        elsif email.present?
          user = User.where(email:email).first
          if user.present?
            person = user.person
            if person.present?
              case role
              when "assister"
                if person.assister_role.present?
                  person.assister_role.destroy
                  person.update(is_disabled:true)
                else
                  puts "Person #{person.full_name} nolonger has #{role}"
                end
              when "cac"
                if person.csr_role.present?
                  person.csr_role.destroy
                  person.update(is_disabled:true)
                else
                  puts "Person #{person.full_name} nolonger has #{role}"
                end
              end
            else
              puts "user with email: #{email} has no person record"
            end
          else
            puts "User not found with email: #{email}"
          end
        end
      end

    end
    puts "Successfully removed roles"
  end
end
