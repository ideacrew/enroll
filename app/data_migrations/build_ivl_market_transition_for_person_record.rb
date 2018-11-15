require File.join(Rails.root, "lib/mongoid_migration_task")

class BuildIvlMarketTransitionForPersonRecord < MongoidMigrationTask

  def migrate
    action = ENV['action'].to_s
    case action
      when 'build_ivl_transitions'
        build_individual_market_transition_for_consumer_role_people
      when 'build_resident_transitions'
        build_individual_market_transition_for_resident_role_people  
      end
  end

  def build_individual_market_transition_for_consumer_role_people
    if ENV['hbx_id'].present?
      person = Person.where(hbx_id: ENV['hbx_id']).first 
      build_market_transitions(person) if person.present?
    else
      people = Person.where(:"consumer_role" => {:"$exists" => true}, :"individual_market_transitions" => {:"$exists" => false})
      people.each do |person|
        build_market_transitions(person)
      end
    end
  end

  def build_individual_market_transition_for_resident_role_people
    person = Person.where(hbx_id: ENV['hbx_id']).first 
    begin
      if (person.individual_market_transitions.present? && person.resident_role.present?)
        return "Individual market transitions are present for this person or this person has no resident role"
      else
        person.individual_market_transitions << IndividualMarketTransition.new(role_type: 'resident',
                                                      reason_code: 'initial_individual_market_transition_created_using_data_migration',
                                                      effective_starting_on:  person.resident_role.created_at.to_date,
                                                      submitted_at: ::TimeKeeper.datetime_of_record)
        puts "Individual market transitions with role type as resident added for person with HBX_ID: #{person.hbx_id}" unless Rails.env.test?
      end
    rescue => e
      puts "unable to add individual market transition for person with hbx_id #{person.hbx_id}" + e.message unless Rails.env.test?
    end
  end

  def build_market_transitions(person)
    begin
        person.individual_market_transitions << IndividualMarketTransition.new(role_type: 'consumer',
                                                       reason_code: 'initial_individual_market_transition_created_using_data_migration',
                                                       effective_starting_on:  person.consumer_role.created_at.to_date,
                                                       submitted_at: ::TimeKeeper.datetime_of_record)
        puts "Individual market transitions with role type as consumer added for person with HBX_ID: #{person.hbx_id}" unless Rails.env.test?
      rescue => e
        puts "unable to add individual market transition for person with hbx_id #{person.hbx_id}" + e.message unless Rails.env.test?
      end
  end
end