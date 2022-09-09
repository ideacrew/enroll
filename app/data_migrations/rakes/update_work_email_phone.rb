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

class UpdateWorkEmailPhone < MongoidMigrationTask
    def migrate
        def email_update
            begin
                    # Verifies work email exists
                    unless @person.emails.where(:kind => "work").first.present?
                        puts "No current Work Email Address found for HBX ID #{@hix}. Please review and run again".red.bold
                        return
                    end

                    # Verifies only one work email exists
                    unless @person.emails.where(:kind => "work").count == 1
                        puts "More than 1 Work Email Address found for HBX ID #{@hix}. Please review and run again.".red.bold
                        return
                    end
                    @email = @person.emails.where(:kind => "work").first

                    # Enter current email address for verification
                    print "\nEnter the CURRENT Email Address for HBX ID #{@hix}: ".cyan
                    current_email_entry = gets
                    @current_email = current_email_entry.chomp

                    # Enter new email address to be updated
                    print "Enter the NEW Email Address to update: ".cyan
                    new_email_entry = gets
                    @new_email = new_email_entry.chomp

                    # Verifies email address entered matches existing work email
                    unless @current_email == @email.address
                        puts "Current Email Address entered does not match work email for HBX ID #{@hix}.\nCurrent Work Email Address is: #{@email}.".red.bold
                        puts "Entered Existing Email: #{@current_email}\nCurrent Email: #{@email.address}\n\n".red.bold
                        return
                    end
                    if @current_email == @email.address
                        # Actual Email Update Takes Place
                        @email.update(:address => @new_email)
                        @email.save
                    end
                rescue => e
                    puts "\n\nEmail Error encountered: #{e}\n\n".red.bold
                end
        end

        def phone_update
            begin
                # Verifies existing work phone number
                unless @person.phones.where(:kind => "work").first.present?
                    puts "No current Work Phone Number found for HBX ID #{@hix}. Please review and run again".red.bold
                    return
                end

                # Verifies only 1 work phone number
                unless @person.phones.where(:kind => "work").count == 1
                    puts "More than 1 Work Phone Number found for HBX ID #{@hix}. Please review and run again.".red.bold
                    return
                end
                @phone = @person.phones.where(:kind => "work").first

                print "\n\nEnter the CURRENT Work Phone Number for HBX ID #{@hix} in format 1112223344: ".cyan
                current_phone_entry = gets
                @current_phone = current_phone_entry.chomp

                # Verifies that entered current phone number is all numeric
                unless @current_phone.numeric?
                    puts "Invalid characters. Please enter only numbers and run again.".red.bold
                    return
                end

                # Verifies length of current phone number is 10
                unless @current_phone.to_s.size == 10
                    puts "\n\nInvalid Entry. Please enter area code and full phone number in format 1112223333 and run again.\n\n".red.bold
                    return
                end

                print "\n\nEnter the NEW Work Phone Number to update to: ".cyan
                new_phone_entry = gets
                @new_phone = new_phone_entry.chomp

                # Verifies entered NEW phone number is numeric
                unless @new_phone.numeric?
                    puts "\n\nInvalid characters. Please enter only numbers and run again.\n\n".red.bold
                    return
                end

                # Verifies entered current phone matches existing work phone number
                unless @current_phone == @phone.full_phone_number
                    puts "\n\nCurrent Work Phone Number entered does not match existing work phone number for HBX ID #{@hix}.\nCurrent Work phone number is: #{@phone}.\n\n".red.bold
                    return
                end

                if @current_phone == @phone.full_phone_number
                    # Actual phone Update Takes Place
                    new_area_code =  @new_phone[0,3]
                    new_number    =  @new_phone[2,7]
                    @phone.update_attributes(:area_code => new_area_code, :number => new_number,:full_phone_number => @new_phone)
                    @phone.save
                end
            rescue => e
                puts "\n\nPhone Error encountered: #{e}\n\n".red.bold
            end
        end

        ##################
        # Working Section

        def make_updates
            begin
                print "Enter the HBX ID for the User Account you wish to update: ".cyan
                hix_entry = gets
                @hix = hix_entry.chomp

                # Verifies person account exists
                unless Person.by_hbx_id(@hix).first.present?
                    puts "No Person Account found for HBX ID #{@hix}. Please review and run again.".red.bold
                    return
                end
                @person = Person.by_hbx_id(@hix).first

                # Choice of email, phone, or both update
                puts "Choose the option below to update (enter number only):".cyan
                puts "  1. Update Display Email Address\n  2. Update Display Phone Number\n  3. Update Both".cyan
                print "\nChoice (enter 1, 2, or 3): ".cyan
                update_entry = gets
                update = update_entry.chomp

                # Case function to interpret input given
                case update
                    when "1"
                        email_update
                    when "2"
                        phone_update
                    when "3"
                        email_update
                        puts "\nEmail update complete. Moving on to Phone update.\n\n".green.bold
                        sleep(1)
                        phone_update
                        puts "\nPhone update complete. Listing verification now.\n".green.bold
                        sleep(1)
                    else
                        puts "Invalid Entry. Please select 1, 2, or 3 when running again.".red.bold
                end
            rescue => e
                puts "\n\nEmail and/or Phone Error encountered: #{e}\n\n".red.bold
            end

            puts "\n\nFollowing Updates have been completed:".green.bold.underline
            if update == "1"
                unless @current_email == @email.address
                    puts "\n\nEmail mismatch. Please investigate before restarting.\n\n".red.bold
                    return
                end
                puts "\n\tWork Email Address for HBX ID #{@hix} updated to #{@person.emails.where(:kind => "work").first.address}.\n\n".green.bold

            elsif update == "2"
                unless @new_phone == @phone.full_phone_number
                    puts "\n\nPhone Number mismatch. Please investigate before restarting.\n\n".red.bold
                    return
                end
                puts "\n\tWork Phone Number for HBX ID #{@hix} updated to #{@person.phones.where(:kind => "work").first.full_phone_number}.\n\n".green.bold

            elsif update == "3"
                unless @new_email == @email.address
                    puts "\n\nEmail mismatch. Please investigate before restarting.\n\n".red.bold
                    return
                end
                unless @new_phone == @phone.full_phone_number
                    puts "\n\nPhone Number mismatch. Please investigate before restarting.\n\n".red.bold
                    return
                end
                puts "\n\t- Work Email Address for HBX ID #{@hix} updated to #{@person.emails.where(:kind => "work").first.address}.".green.bold
                puts "\t- Work Phone Number for HBX ID #{@hix} updated to #{@person.phones.where(:kind => "work").first.full_phone_number}.\n\n".green.bold
            end
        end
    end
end
