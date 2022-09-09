require File.join(Rails.root, 'lib/mongoid_migration_task')

class String
    def black;          "\e[30m#{self}\e[0m" end
    def red;            "\e[31m#{self}\e[0m" end
    def green;          "\e[32m#{self}\e[0m" end
    def brown;          "\e[33m#{self}\e[0m" end
    def blue;           "\e[34m#{self}\e[0m" end
    def magenta;        "\e[35m#{self}\e[0m" end
    def cyan;           "\e[36m#{self}\e[0m" end
    def gray;           "\e[37m#{self}\e[0m" end

    def bg_black;       "\e[40m#{self}\e[0m" end
    def bg_red;         "\e[41m#{self}\e[0m" end
    def bg_green;       "\e[42m#{self}\e[0m" end
    def bg_brown;       "\e[43m#{self}\e[0m" end
    def bg_blue;        "\e[44m#{self}\e[0m" end
    def bg_magenta;     "\e[45m#{self}\e[0m" end
    def bg_cyan;        "\e[46m#{self}\e[0m" end
    def bg_gray;        "\e[47m#{self}\e[0m" end

    def bold;           "\e[1m#{self}\e[22m" end
    def italic;         "\e[3m#{self}\e[23m" end
    def underline;      "\e[4m#{self}\e[24m" end
    def blink;          "\e[5m#{self}\e[25m" end
    def reverse_color;  "\e[7m#{self}\e[27m" end
end

class MoveUserAccountBetweenTwoPersonAccounts < MongoidMigrationTask
    def migrate
        begin
            # Person that user account is moving FROM
            print "Enter the HBX ID of the User you wish to move the User Account FROM: ".cyan
            from_hix_entry = gets
            from_hix = from_hix_entry.chomp

            # Validates person account is present
            unless Person.by_hbx_id(from_hix).first.present?
                puts "\n\nNo Person Account found for HBX ID #{from_hix}. Please review and run again.\n\n".red.bold
                return
            end
            from_person = Person.by_hbx_id(from_hix).first

            # Validates that user account is present
            unless from_person.user.present?
                puts "\n\nNo User Account found for HBX ID #{from_hix}. Please review and run again.".red.bold
                return
            end
            user  =  from_person.user
            login =  user.oim_id

            # Person that user account is moving TO
            print "Enter the HBX ID of the Person you wish to move the User Account TO: ".cyan
            to_hix_entry = gets
            to_hix = to_hix_entry.chomp

            # Verifies 2nd person account is present
            unless Person.by_hbx_id(to_hix).first.present?
                puts "\n\nNo Person Account found for HBX ID #{to_hix}. Please review and run again.\n\n".red.bold
                return
            end
            to_person = Person.by_hbx_id(to_hix).first

            if to_person.user.present?
                puts "Person with HBX ID #{to_hix} currently has a user account with login #{to_person.user.oim_id}. Unable to move User Account from HBX ID #{from_hix}. Please review and run again.".red.bold
            # Moving user account
            else
                user_id = from_person.user_id
                from_person.unset(:user_id)
                to_person.set(:user_id => user_id)
                puts "\n\nUser Account successfully moved from HBX ID #{from_hix} to HBX ID #{to_hix}.\n".green.bold

                puts "\n\nVerification:
                HBX ID: #{to_hix}
                Name: #{to_person.full_name}
                Username: #{to_person.user.oim_id}
                Email: #{to_person.user.email}\n\n".green
            end
        rescue => e
            puts "Error during move process: #{e}".red.bold
        end
    end
end
