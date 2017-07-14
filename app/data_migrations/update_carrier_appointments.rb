require File.join(Rails.root, "lib/mongoid_migration_task")

class UpdateCarrierAppointments < MongoidMigrationTask
  def migrate

    mappings = {
                "Altus Dental" => "Altus Dental",
                "Blue Cross Blue Shield of MA" => "Blue Cross Blue Shield of MA",
                "Boston Medical Center Health Planc" => "Boston Medical Center Health Planc",
                "Delta Dental" => "Delta Dental",
                "Kaiser Foundation" => "Kaiser Foundation",
                "Guardian" => "Guardian",
                "Health New England" => "Health New England",
                "Harvard Pilgrim Health Car" => "Harvard Pilgrim Health Car",
                "Minuteman Health" => "Minuteman Health",
                "Neighborhood Health Plan" => "Neighborhood Health Plan",
                "Tufts Health Plan Direct" => "Tufts Health Plan Direct",
                "Tufts Health Plan Premier" => "Tufts Health Plan Premier"
               }
    BrokerRole.all.each do |br|
      if br.carrier_appointments.all?{|key, value| key.include?('_') }
          br.carrier_appointments = br.carrier_appointments.map {|k, v| [mappings[k], v] }.to_h
          br.save
      elsif br.carrier_appointments.all?{|key, value| !key.include?('_') }
        #Do NOTHING
      else
        all_carrier_appointment = BrokerRole::BROKER_CARRIER_APPOINTMENTS.stringify_keys
        data = br.carrier_appointments.map {|k, v| mappings[k] ? [mappings[k], v] : nil}.compact.to_h
        br.carrier_appointments = all_carrier_appointment.merge! data
        br.save
      end
    end
  end
end
