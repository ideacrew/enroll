require 'csv'

def ridp_type_status(type, person)
  consumer = person.consumer_role
  case type
  when 'Identity'
    if consumer.identity_verified?
      consumer.identity_validation
    elsif consumer.has_ridp_docs_for_type?(type) && !consumer.identity_rejected
      'in review'
    else
      'outstanding'
    end
  when 'Application'
    if consumer.application_verified?
      consumer.application_validation
    elsif consumer.has_ridp_docs_for_type?(type) && !consumer.application_rejected
      'in review'
    else
      'outstanding'
    end
  end
end

field_names = %w[person_full_name person_hbx_id verification_type updated_from updated_to]
file_name = "#{Rails.root}/consumers_with_updated_ridp_fields.csv"

CSV.open(file_name, "w", force_quotes: true) do |csv|
  csv << field_names
  Person.for_admin_approval.each do |person|
    begin
      consumer = person.consumer_role
      person.ridp_verification_types.each do |type|
        validation_value = consumer.send("#{type.downcase}_validation".to_sym)
        case ridp_type_status(type, person)
        when 'valid'
          if validation_value != 'valid'
            consumer.update_attributes!("#{type.downcase}_validation".to_sym => 'valid')
            csv << [person.full_name, person.hbx_id, type, validation_value, 'valid']
          end
        when 'outstanding'
          if validation_value != 'outstanding'
            consumer.update_attributes!("#{type.downcase}_validation".to_sym => 'outstanding')
            csv << [person.full_name, person.hbx_id, type, validation_value, 'outstanding']
          end
        end
      end
    rescue => e
      puts "Cannot process person, hbx_id: #{person.hbx_id}, error: #{e.message}" unless Rails.env.test?
    end
  end
end
