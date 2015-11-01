require Rails.root.join('lib', 'tasks', 'hbx_import', 'qhp', 'parsers', 'plan_benefit_template_parser')
require Rails.root.join('lib', 'object_builders', 'qhp_builder.rb')
require Rails.root.join('lib', 'tasks', 'hbx_import', 'qhp', 'parsers', 'plan_rate_group_parser')
require Rails.root.join('lib', 'object_builders', 'qhp_rate_builder.rb')

namespace :seed do
  UNUSED_DENTEGRA_HIOS_IDS = ["96156DC0020006", "96156DC0020001", "96156DC0020004"] # These plans are not present in master sheet. having these plans is causing comparion page show empty data.
  desc "Load the plan data"
  task :plans => :environment do
    Plan.delete_all
    plan_file = File.open("db/seedfiles/plans.json", "r")
    data = plan_file.read
    plan_file.close
    plan_data = JSON.load(data)
    plan_data.each do |pd|
      Plan.create!(pd) unless UNUSED_DENTEGRA_HIOS_IDS.include?(pd["hios_id"])
    end
  end
end

namespace :delete do
  desc "delete fake plans"
  task :fake_plans => :environment do
    Plan.where(:hios_id.in => [/123523/, /120523/, /191503/, /194303/]).each do |plan|
      plan.destroy
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
          new_plans = Plan.where(hios_id: /#{new_hios_id}/, active_year: 2016)
          new_plans.each do |new_plan|
            if new_plan.present? && new_plan.csr_variant_id != "00"
              old_plan = Plan.where(hios_id: /#{old_hios_id}/, active_year: 2015, csr_variant_id: /#{new_plan.csr_variant_id}/ ).first
              if old_plan.present?
                old_plan.update(renewal_plan_id: new_plan._id)
                puts "Old plan hios_id #{old_plan.hios_id} renewed with New plan hios_id: #{new_plan.hios_id}"
                updated_hios_ids_list << old_plan.hios_id
              else
              puts "No plan found for hios id: '#{new_hios_id}'"
              end
            end
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
        rejected_hios_ids_list << old_hios_id
        # new_plan = Plan.where(hios_id: /#{new_hios_id}/, active_year: 2016, :csr_variant_id.in => ["","01"]).first
        # Plan.where(hios_id: /#{old_hios_id}/, active_year: 2015, :csr_variant_id.in => ["","01"]).each do |pln|
        #   pln.update(renewal_plan_id: new_plan._id)
        #   puts "Old plan hios_id #{pln.hios_id} renewed with New plan hios_id: #{new_plan.hios_id}"
        #   updated_hios_ids_list << pln.hios_id
        # end
      end
      old_plan_hios_ids = old_plan_hios_ids.map { |str| str[0..13] }.uniq
      updated_hios_ids_list = updated_hios_ids_list.map { |str| str[0..13] }.uniq
      no_change_in_hios_ids = old_plan_hios_ids - (updated_hios_ids_list + rejected_hios_ids_list)
      no_change_in_hios_ids = no_change_in_hios_ids.uniq
      no_change_in_hios_ids.each do |hios_id|
        new_plans = Plan.where(hios_id: /#{hios_id}/, active_year: 2016)
        new_plans.each do |new_plan|
          old_plan = Plan.where(active_year: 2015, hios_id: /#{hios_id}/, csr_variant_id: new_plan.csr_variant_id).first
          if new_plan.present? && new_plan.csr_variant_id != "00" && old_plan.present?
            if old_plan.present?
              old_plan.update(renewal_plan_id: new_plan.id)
            end
            puts "Old plan hios_id #{old_plan.hios_id} carry overed with New plan hios_id: #{new_plan.hios_id}"
          else
            puts "plan not present : #{hios_id}"
          end
        end
      end
      standard_hios_ids = ["94506DC0390001-01","94506DC0390005-01","94506DC0390007-01","94506DC0390011-01","86052DC0400001-01","86052DC0400002-01","86052DC0400007-01","86052DC0400008-01","78079DC0210001-01","78079DC0210002-01","78079DC0210003-01","78079DC0210004-01"]
      Plan.by_active_year(2016).where(:hios_id.in => standard_hios_ids).each do |plan|
        plan.update(is_standard_plan: true)
        puts "Plan with hios_id #{plan.hios_id} updated to standard plan."
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
    # xml = Nokogiri::XML(File.open(args.file))
    # plan = Parser::PlanBenefitTemplateParser.parse(xml.root.canonicalize, :single => true)
    # qhp_hash = QhpBuilder.new(plan.to_hash)
    # qhp_hash.run

    files = Dir.glob(File.join(Rails.root, "db/seedfiles/plan_xmls", "plans", "**", "*.xml"))
    qhp_import_hash = files.inject(QhpBuilder.new({})) do |qhp_hash, file|
      puts file
      xml = Nokogiri::XML(File.open(file))
      plan = Parser::PlanBenefitTemplateParser.parse(xml.root.canonicalize, :single => true)
      qhp_hash.add(plan.to_hash, file)
      qhp_hash
    end

    qhp_import_hash.run
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
