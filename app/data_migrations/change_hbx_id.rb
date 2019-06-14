
require File.join(Rails.root, "lib/mongoid_migration_task")

class ChangeHbxId< MongoidMigrationTask
  def migrate
    begin
      action = ENV['action'].to_s
      hbx_id = ENV['hbx_id']
      if ENV['new_hbx_id'].present? 
        new_hbx_id = ENV['new_hbx_id']
      elsif action = "change_person_hbx"
        new_hbx_id = HbxIdGenerator.generate_member_id
      else
        new_hbx_id = HbxIdGenerator.generate_organization_id
      end

      case action
      when "change_person_hbx"
        change_person_hbx(hbx_id,new_hbx_id)
      when "change_organization_hbx"
        change_organization_hbx(hbx_id,new_hbx_id)
      end
      
      def change_organization_hbx(hbx_id,new_hbx_id)
        organization = Organization.where(hbx_id: hbx_id).first
        if organization.nil?
          puts "No organization was found by the given hbx_id: #{hbx_id}" unless Rails.env.test?
        elsif !new_hbx_id.present?
          puts "No new hbx id is provided" unless Rails.env.test?
        else
          organization.update_attributes(hbx_id: new_hbx_id)
          puts "Change Hbx Id: #{hbx_id} to #{new_hbx_id} " unless Rails.env.test?
        end
      end
    rescue => e
      puts "#{e}"
    end
  end
end



