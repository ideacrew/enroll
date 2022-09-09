require File.join(Rails.root, "lib/mongoid_migration_task")

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

class DisablePersonAccount< MongoidMigrationTask
    def migrate
        begin
            print "Enter the HBX ID for the Person Account you wish to disable: ".cyan
            hix_entry = gets
            hix = hix_entry.chomp

            # Verify that person account exists
            unless Person.by_hbx_id(hix).first.present?
                puts "No Person Account found for HBX ID #{hix}. Please review and run again.".red.bold
                return
            end
            person = Person.by_hbx_id(hix).first

            # Verify Person account is currently active
            unless person.is_active == true
                puts "\n\nAccount with HBX ID #{hix} is already disabled. Thank you.".red.bold
                return
            end

            # Update being made
            person.update_attributes(:is_active => false, :is_disabled => true)
            person.save

            puts "\n\nPerson Account for #{person.full_name} (HBX ID #{hix}) is now disabled. Thank you.\n\n".green.bold

            # Performs check to see if there is a related user account
            if person.user.present?
                user = person.user
                puts "Please note: HBX ID #{hix} also has an active User Account with username #{user.oim_id}.".red.bold
                print "Do you wish to remove the associated User Account as well? (y or n): ".cyan
                user_remove_entry = gets
                user_remove = user_remove_entry.chomp.downcase

                case user_remove
                    when "y"
                        # Removes user account
                        user.delete
                        puts "\n\nUser account for HBX ID #{hix} has been removed. Thank you.".green.bold
                    when "n"
                        puts "\n\nUser Account #{user.oim_id} will not be disabled or removed.".red.bold
                    else
                        puts "Invalid Entry. Must choose y or n. Please run again.".red.bold
                end
            end
        rescue => e
            puts "\n\nError encountered: #{e}".red.bold
        end
    end
end
