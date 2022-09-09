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

class TermCancelEnrollment < MongoidMigrationTask
    def migrate
        print "Enter HBX ID of Enrollment to Terminate or Cancel: ".cyan
        enrollment_hix_entry = gets
        enrollment_hix = enrollment_hix_entry.chomp

        unless HbxEnrollment.by_hbx_id(enrollment_hix).first.present?
            puts "\n\nNo enrollment found with HBX ID #{enrollment_hix}. Please review and run again.".red.bold
            return
        end
        enrollment        =  HbxEnrollment.by_hbx_id(enrollment_hix).first
        enrollment_status =  enrollment.aasm_state

        puts "\n\nEnrollment with HBX ID #{enrollment_hix} is currently in status #{enrollment_status}.\n\n".brown
        puts "Choose the status you wish to update the enrollment to:".cyan

        puts "  \n**********************\n  1. Cancel Enrollment\n  2. Terminate Enrollment\n".cyan
        print "Enter the number of your selection: ".cyan

        update_enrollment_entry = gets
        update_enrollment = update_enrollment_entry.chomp

        begin
            case update_enrollment
                when "1"
                    enrollment.update(:aasm_state => "coverage canceled")
                    puts "\n\nCoverage for Enrollment HBX ID #{enrollment_hix} has been canceled. Thank you.".green.bold
                when "2"
                    print "\nEnter date for Termination using 'mm/dd/yy' format: ".cyan
                    term_date_entry  =  gets
                    term_date        =  term_date_entry.chomp
                    termination_date =  Date.strptime(term_date.to_s, "%m/%d/%Y")
                    terminated_on    =  termination_date.end_of_month

                    enrollment.terminate_coverage!(terminated_on)
                    enrollment.update(:termination_submitted_on => termination_date)
                    enrollment.save
                    puts "\n\nCoverage for Enrollment HBX ID #{enrollment_hix} has been terminated effective '#{terminated_on}' (date entered: #{termination_date}. Thank you.)".green.bold
                else
                    "\n\nInvalid entry. Please run again and enter the number of your selection.\n\n".red.bold
            end
        rescue => e
            puts e
        end
    end
end
