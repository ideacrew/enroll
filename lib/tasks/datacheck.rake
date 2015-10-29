require 'csv'

namespace :datacheck do
  # USAGE  rake datacheck:network['MASTER 2016 QHP_QDP IVAL & SHOP Plan and Rate Matrix v.9.2.xlsx']
  task :network, [:file_path] => :environment do |task, args|
    SHEETS = ['IVL', 'SHOP Q1', 'SHOP Q2', 'SHOP Q3', 'SHOP Q4']

    xls = Roo::Spreadsheet.open(args.file_path)
    SHEETS.each do |sheet_name|
      last_row = xls.sheet(sheet_name).last_row
      (2..last_row).each do |i|
        row = xls.sheet(sheet_name).row(i)
        hios_id = row[2]
        plan_name = row[3].gsub(/\A\p{Space}*|\p{Space}*\z/, '')
        network = row[5]
        #puts "#{plan_name} #{network}"
        plans = Plan.where(active_year: '2016').and(name: plan_name)

        if network.nil?
          puts "network nil #{hios_id} #{plan_name} #{network}"
          next
        end

        if plans.nil?
          puts "Plan not found #{hios_id} #{plan_name} #{network}"
          next
        end

        plans.each do |plan|
          if plan.nationwide
            if network.include?("Nationwide")
              puts "Network match #{hios_id} #{plan_name} #{network}"
            else
              puts "Network MISSMATCH #{hios_id} #{plan_name} #{network}"
            end
          end

          if plan.dc_in_network
            if network.include?("DC")
              puts "Network match #{hios_id} #{plan_name} #{network}"
            else
              puts "Network MISSMATCH #{hios_id} #{plan_name} #{network}"
            end
          end
        end
      end
    end
  end
end