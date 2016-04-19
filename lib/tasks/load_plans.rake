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

namespace :serff do
  desc "Update cost share variances for assisted"
  task :update_cost_share_variances => :environment do
    Plan.where(:active_year.in => [2015, 2016]).each do |plan|
      qhp = Products::Qhp.where(active_year: plan.active_year, standard_component_id: plan.hios_base_id).first
      hios_id = plan.coverage_kind == "dental" ? (plan.hios_id + "-01") : plan.hios_id
      if hios_id.split("-").last != "01"
        csr = qhp.qhp_cost_share_variances.where(hios_plan_and_variant_id: hios_id).to_a.first
        puts "#{hios_id} ::: #{csr.hios_plan_and_variant_id}"
        plan.deductible = csr.qhp_deductable.in_network_tier_1_individual
        plan.family_deductible = csr.qhp_deductable.in_network_tier_1_family
        plan.save
      end
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
        last_row = sheet == "IVL HIOS Plan Crosswalk" ? sheet_data.last_row : 118
        (2..last_row).each do |row_number| # update renewal plan_ids
          carrier, old_hios_id, old_plan_name, new_hios_id, new_plan_name = sheet_data.row(row_number)
          if new_hios_id.present?
          new_plans = Plan.where(hios_id: /#{new_hios_id.squish}/, active_year: 2016)
            new_plans.each do |new_plan|
              if new_plan.present? && new_plan.csr_variant_id != "00"
                old_plan = Plan.where(hios_id: /#{old_hios_id.squish}/, active_year: 2015, csr_variant_id: /#{new_plan.csr_variant_id}/ ).first
                if old_plan.present?
                  old_plan.update(renewal_plan_id: new_plan._id)
                  puts "Old plan hios_id #{old_plan.hios_id} renewed with New plan hios_id: #{new_plan.hios_id}"
                  updated_hios_ids_list << old_plan.hios_id
                else
                puts "No plan found for hios id: '#{new_hios_id}'"
                end
              end
            end
          else
            puts " #{carrier} plan with 2015 hios id : #{old_hios_id} is retired."
            rejected_hios_ids_list << old_hios_id
          end
        end
      end
      # for aetna cross walk
      rejected_hios_ids_list << ["77422DC0060002", "77422DC0060004", "77422DC0060005", "77422DC0060006", "77422DC0060008", "77422DC0060010"]
      old_plan_hios_ids = old_plan_hios_ids.map { |str| str[0..13] }.uniq
      updated_hios_ids_list = updated_hios_ids_list.map { |str| str[0..13] }.uniq
      no_change_in_hios_ids = old_plan_hios_ids - (updated_hios_ids_list + rejected_hios_ids_list)
      no_change_in_hios_ids = no_change_in_hios_ids.uniq
      no_change_in_hios_ids.each do |hios_id|
        new_plans = Plan.where(hios_id: /#{hios_id.squish}/, active_year: 2016)
        new_plans.each do |new_plan|
          old_plan = Plan.where(active_year: 2015, hios_id: /#{hios_id.squish}/, csr_variant_id: new_plan.csr_variant_id).first
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
    files = Dir.glob(File.join(Rails.root, "db/seedfiles/plan_xmls", "plans", "**", "*.xml"))
    # files = Dir.glob(File.join(Rails.root, "db/seedfiles/plan_xmls", "plans", "**", "Best Life IVL Plan Benefits Template.xml"))
    qhp_import_hash = files.inject(QhpBuilder.new({})) do |qhp_hash, file|
      puts file
      xml = Nokogiri::XML(File.open(file))
      plan = Parser::PlanBenefitTemplateParser.parse(xml.root.canonicalize, :single => true)
      qhp_hash.add(plan.to_hash, file)
      qhp_hash
    end

    qhp_import_hash.run
  end
end

namespace :xml do
  desc "Import qhp rates from xml files"
  task :rates, [:action] => :environment do |task, args|
    files = Dir.glob(File.join(Rails.root, "db/seedfiles/plan_xmls", "rates", "**", "*.xml"))
    rate_import_hash = files.inject(QhpRateBuilder.new()) do |rate_hash, file|
      action = args[:action] == "update" ? "update" : "new"
      puts file
      xml = Nokogiri::XML(File.open(file))
      rates = Parser::PlanRateGroupParser.parse(xml.root.canonicalize, :single => true)
      rate_hash.add(rates.to_hash, action)
      rate_hash
    end
    rate_import_hash.run

  end
end