require Rails.root.join('lib', 'tasks', 'hbx_import', 'broker', 'parsers', 'broker_parser')

namespace :xml do
  desc "Import brokers from xml files"
  namespace :import do
    task :broker, [:file] => :environment do |task, args|
      xml = Nokogiri::XML(File.open(args.file))
      broker = Parser::BrokerParser.parse(xml.root.canonicalize)
      puts broker.map(&:to_hash)
    end
  end
end