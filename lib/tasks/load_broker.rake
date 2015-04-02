require Rails.root.join('lib', 'tasks', 'hbx_import', 'broker', 'parsers', 'broker_parser')
require Rails.root.join('lib', 'object_builders', 'broker_role_builder')

log_path = "#{Rails.root}/log/rake_xml_import_broker_#{Time.now.to_s.gsub(' ', '')}.log"
logger = Logger.new(log_path)

namespace :xml do
  desc "Import brokers from xml files"
  task :broker, [:file] => :environment do |task, args|
    brokers = []

    begin
      xml = Nokogiri::XML(File.open(args.file))
      brokers = Parser::BrokerParser.parse(xml.root.canonicalize)
    rescue Exception => e
      logger.error "Failed to create broker #{e.message}"
    end

    puts "Total number of brokers form xml: #{brokers.count}"

    counter = 0
    brokers.each do |broker|
      begin
        broker_role_builder = BrokerRoleBuilder.new(broker.to_hash)
        broker_role_builder.build
        broker_role_builder.save!
        counter = counter + 1
        logger.info "Saved broker #{broker_role_builder.person.first_name} #{broker_role_builder.person.last_name}"
      rescue Exception => e
        logger.error "Failed to create broker #{broker.to_hash[:name][:first_name]} #{broker.to_hash[:name][:last_name]} \n#{e.message} #{broker_role_builder.person.errors.full_messages} \nbroker_hash#{broker.to_hash}"
      end
    end

    puts "Total number of brokers saved to database: #{counter}"
    puts "Check the log file #{log_path}"

  end
end