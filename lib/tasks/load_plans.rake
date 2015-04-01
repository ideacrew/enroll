require Rails.root.join('lib', 'tasks', 'hbx_import', 'qhp', 'parsers', 'plan_benefit_template_parser')
require Rails.root.join('lib', 'object_builders', 'qhp_builder.rb')


namespace :seed do
  desc "Load the plan data"
  task :plans => :environment do
    Plan.delete_all
    plan_file = File.open("db/seedfiles/plans.json", "r")
    data = plan_file.read
    plan_file.close
    plan_data = JSON.load(data)
    plan_data.each do |pd|
      Plan.create!(pd)
    end
  end
end


namespace :xml do
  desc "Import qhp plans from xml files"
  namespace :import do
    task :plans, [:file] => :environment do |task, args|
      # files = Dir.glob(File.join(args.dir, "**", "*.xml"))
      # files.each do |file|
      # #   puts file
        xml = Nokogiri::XML(File.open(args.file))
        plan = Parser::PlanBenefitTemplateParser.parse(xml.root.canonicalize, :single => true)
        qhp_hash = QhpBuilder.new(plan.to_hash)
        qhp_hash.build_and_save
      #   exit
      # end
    end
  end
end

