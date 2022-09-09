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

class AddPrimaryFamilyToPerson < MongoidMigrationTask
  def migrate
    begin
        print "Enter the HBX ID for the person you wish to add a Primary Family to: ".cyan
        hix_entry = gets
        hix = hix_entry.chomp

        # Verifies presence of person account
        unless Person.by_hbx_id(hix).first.exists?
            puts "\n\nNo Person Account found for HBX ID #{hix}. Please review and run again.\n\n".red.bold
            return
        end
        person = Person.by_hbx_id(hix).first

        # Verifies primary family is not present
        unless family.find_family_member_by_person(person).present? == false
            puts "Primary Family already exists for HBX ID #{hix}. Please review and run again if necessary.".red.bold
            return
        end

        # Adding primary family
        family = Family.new
        primary_applicant = family.add_family_member(person, :is_primary_applicant => true)

        person.relatives.each do |related_person|
            family.add_family_member(related_person)
        end

        family.family_members.map(&:__association_reload_on_person)
        family.save!

        puts "Primary Family successfully added to #{person.full_name} (HBX ID: #{hix}). Thank you.".green.bold
    rescue => e
        puts "Error encountered: #{e}"
        end
    end
end
