require Rails.root.join('lib', 'tasks', 'hbx_import', 'qhp', 'parsers', 'plan_benefit_template_parser')
require Rails.root.join('lib', 'object_builders', 'qhp_builder.rb')
require Rails.root.join('lib', 'tasks', 'hbx_import', 'qhp', 'parsers', 'plan_rate_group_parser')
require Rails.root.join('lib', 'object_builders', 'qhp_rate_builder.rb')
require 'roo'

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
  task :renewal_plans, [:file] => :environment do |task,args|
    files = Dir.glob(File.join(Rails.root, "db/seedfiles/plan_xmls", "**", "*.xlsx"))
    if files.present?
      result = Roo::Spreadsheet.open(files.first)
      sheets = ["IVL HIOS Plan Crosswalk", "SHOP HIOS Plan Crosswalk"]
      sheets.each do |sheet|
        sheet_data = result.sheet(sheet)
        last_row = sheet == "IVL HIOS Plan Crosswalk" ? sheet_data.last_row : 58
        (2..last_row).each do |row_number|
          carrier, old_hios_id, old_plan_name, new_hios_id, new_plan_name = sheet_data.row(row_number)
          old_plan = Plan.where(hios_id: /#{old_hios_id}/, active_year: 2015).first
          new_plan = Plan.where(hios_id: /#{new_hios_id}/, active_year: 2016).first
          old_plan.update(renewal_plan_id: new_plan._id)
          puts "Old plan hios_id #{old_plan.hios_id} renewed with New plan hios_id: #{new_plan.hios_id}"
        end
      end
    end
  end
end

namespace :xml do
  desc "Import qhp plans from xml files"
  task :plans, [:file] => :environment do |task, args|
  # files = Dir.glob(File.join(args.dir, "**", "*.xml"))
  # files.each do |file|
  # #   puts file
    xml = Nokogiri::XML(File.open(args.file))
    plan = Parser::PlanBenefitTemplateParser.parse(xml.root.canonicalize, :single => true)
    qhp_hash = QhpBuilder.new(plan.to_hash)
    qhp_hash.run
  #   exit
  # end
  end
end

namespace :xml do
  desc "Import all qhp plans from xml files in a directory"
  task :serff, [:dir] => :environment do |task, args|
    files = Dir.glob(File.join(args.dir, "**", "*.xml"))
    files.each do |file|
      # #   puts file
      xml = Nokogiri::XML(File.open(file))
      plan = Parser::PlanBenefitTemplateParser.parse(xml.root.canonicalize, :single => true)
      qhp_hash = QhpBuilder.new(plan.to_hash)
      qhp_hash.run
    end
  end
end
