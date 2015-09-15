require Rails.root.join('lib', 'tasks', 'hbx_import', 'qhp', 'parsers', 'plan_benefit_template_parser')
require Rails.root.join('lib', 'object_builders', 'qhp_builder.rb')
require Rails.root.join('lib', 'tasks', 'hbx_import', 'qhp', 'parsers', 'plan_rate_group_parser')
require Rails.root.join('lib', 'object_builders', 'qhp_rate_builder.rb')

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

#FIXME
#TODO
#REFACTOR, move code to models or relevent place.
namespace :xml do
  task :renewal_and_standard_plans, [:file] => :environment do |task,args|
    files = Dir.glob(File.join(Rails.root, "db/seedfiles/plan_xmls", "**", "*.xlsx"))
    if files.present?
      puts files
      result = Roo::Spreadsheet.open(files.first)
      updated_hios_ids_list = []
      rejected_hios_ids_list = []
      old_plan_hios_ids = Plan.where(active_year: 2015).map(&:hios_id)
      sheets = ["IVL HIOS Plan Crosswalk", "SHOP HIOS Plan Crosswalk"]
      sheets.each do |sheet|
        sheet_data = result.sheet(sheet)
        last_row = sheet == "IVL HIOS Plan Crosswalk" ? sheet_data.last_row : 59
        (2..last_row).each do |row_number| # update renewal plan_ids
          carrier, old_hios_id, old_plan_name, new_hios_id, new_plan_name = sheet_data.row(row_number)
          new_plan = Plan.where(hios_id: /#{new_hios_id}/, active_year: 2016).first
          if new_plan
            Plan.where(hios_id: /#{old_hios_id}/, active_year: 2015).each do |pln|
              pln.update(renewal_plan_id: new_plan._id)
              puts "Old plan hios_id #{pln.hios_id} renewed with New plan hios_id: #{new_plan.hios_id}"
              updated_hios_ids_list << pln.hios_id
            end
          else
            puts "No plan found for hios id: '#{new_hios_id}'"
          end
        end
        if sheet == "SHOP HIOS Plan Crosswalk"
          (60..118).each do |row_number| # rejected hios ids
            carrier, old_hios_id, old_plan_name, new_hios_id, new_plan_name = sheet_data.row(row_number)
            rejected_hios_ids_list << old_hios_id
          end
        end
      end
      # for aetna cross walk
      sheet_data = result.sheet("Aetna Transition Out IVL")
      (3..8).each do |row_number|
        old_carrier, old_hios_id, old_plan_name, new_carrier, new_hios_id, new_plan_name = sheet_data.row(row_number)
        new_plan = Plan.where(hios_id: /#{new_hios_id}/, active_year: 2016).first
        Plan.where(hios_id: /#{old_hios_id}/, active_year: 2015).each do |pln|
          pln.update(renewal_plan_id: new_plan._id)
          puts "Old plan hios_id #{pln.hios_id} renewed with New plan hios_id: #{new_plan.hios_id}"
          updated_hios_ids_list << pln.hios_id
        end
      end
      old_plan_hios_ids = old_plan_hios_ids.map { |str| str[0..13] }.uniq
      updated_hios_ids_list = updated_hios_ids_list.map { |str| str[0..13] }.uniq
      no_change_in_hios_ids = old_plan_hios_ids - (updated_hios_ids_list + rejected_hios_ids_list)
      no_change_in_hios_ids = no_change_in_hios_ids.uniq
      no_change_in_hios_ids.each do |hios_id|
        new_plan = Plan.where(active_year: 2016, hios_id: /#{hios_id}/).first
        if new_plan.present?
          Plan.where(active_year: 2015, hios_id: /#{hios_id}/).each do |old_plan|
          old_plan.update(renewal_plan_id: new_plan.id)
            puts "Old plan hios_id #{old_plan.hios_id} carry overed with New plan hios_id: #{new_plan.hios_id}"
          end
        else
          puts "plan not present: #{hios_id}"
        end
      end
      sheet_data = result.sheet("IVL CSR IDs")
      (2..94).each do |row_number|
        carrier, hios_id, plan_name, metal_level, csr_variation_type = sheet_data.row(row_number)
        hios_base_id = hios_id.split("-").first
        csr_variant_id = hios_id.split("-").last
        plan = Plan.where(active_year: 2016, hios_base_id: /#{hios_base_id}/, csr_variant_id: /#{csr_variant_id}/).first
        if plan
          plan.update(is_standard_plan: true)
          puts "plan with hios id #{hios_base_id}-#{csr_variant_id} updated to standard plan."
        else
          puts "plan with hios id #{hios_base_id}-#{csr_variant_id} was not found and not updated to standard plan."
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
