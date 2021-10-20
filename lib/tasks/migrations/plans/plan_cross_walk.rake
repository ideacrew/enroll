require Rails.root.join('lib', 'tasks', 'hbx_import', 'plan_cross_walk_list_parser')
namespace :xml do
  desc "Import plan crosswalk"
  task :plan_cross_walk, [:file] => :environment do |task, args|
    files = Rails.env.test? ? [args[:file]] : Dir.glob(File.join(Rails.root, "db/seedfiles/plan_xmls", Settings.aca.state_abbreviation.downcase, "cross_walk", "**", "*.xml"))

    files.each do |file_path|
      puts "*"*80 unless Rails.env.test?
      puts "processing: #{file_path}" unless Rails.env.test?
      @file_path = file_path
      @current_year = file_path.split("/")[-2].to_i # Retrieve the year of the master xml file you are uploading
      @previous_year = @current_year - 1
      xml = Nokogiri::XML(File.open(@file_path))
      result = Parser::PlanCrossWalkListParser.parse(xml.root.canonicalize, :single => true)
      cross_walks = result.to_hash[:crosswalks]
      process_plans(cross_walks)
      process_products(cross_walks)
    end
  end

  def process_plans(cross_walks)
    cross_walks.each do |row|
      old_hios_id = if row["plan_id_#{@previous_year}_hios".to_sym].present?
        row["plan_id_#{@previous_year}_hios".to_sym]
      else
        row["plan_id_cy".to_sym]
      end.squish
      new_hios_id = if row["plan_id_#{@current_year}_hios".to_sym].present?
        row["plan_id_#{@current_year}_hios".to_sym]
      else
        row["plan_id_fy".to_sym]
      end.squish

      is_this_plan_catastrophic_or_child_only_plan = row[:is_this_plan_catastrophic_or_child_only_plan]&.squish&.downcase
      cat_hios_id = row["plan_id_#{@current_year}_for_enrollees_aging_off_catastrophic_or_child_only_plan".to_sym]&.squish
      cat_hios_id ||= row[:plan_id_for_enrollees_aging_off_catastrophic_or_child_only_plan_fy]
      new_plans =  Plan.where(hios_id: /#{new_hios_id}/, active_year: @current_year)
      # to handle cases when business provides us with a renewal mapping
      # and then updates the template to say that the old plan got retired with no new mapping.
      if new_hios_id.blank?
        old_plans = Plan.where(hios_id: /#{old_hios_id}/, active_year: @previous_year)
        old_plans.each do |old_plan|
          old_plan.update(renewal_plan_id: nil)
          puts "Old #{@previous_year} #{old_plan.carrier_profile.legal_name} plan hios_id #{old_plan.hios_id} retired" unless Rails.env.test?
        end
      else
        new_plans.each do |new_plan|
          if new_plan.present? && new_plan.csr_variant_id != "00"
            old_plan = Plan.where(hios_id: /#{old_hios_id}/, active_year: @previous_year, csr_variant_id: /#{new_plan.csr_variant_id}/).first
            if old_plan.present?
              old_plan.update(renewal_plan_id: new_plan.id)
              if is_this_plan_catastrophic_or_child_only_plan == "yes" && new_plan.csr_variant_id == "01" && new_plan.coverage_kind == "health"
                cat_age_off_renewal_plan = Plan.where(hios_id: /#{cat_hios_id}/,active_year: @current_year,csr_variant_id: "01").first
                old_plan.update(cat_age_off_renewal_plan_id: cat_age_off_renewal_plan.id)
                puts "Successfully mapped #{@previous_year} #{old_plan.carrier_profile.legal_name} cat age off plan with hios_id #{old_plan.hios_id} to #{@current_year} #{cat_age_off_renewal_plan.carrier_profile.legal_name} plan_hios_id: #{cat_age_off_renewal_plan.hios_id}" unless Rails.env.test?
              end
              puts "Old #{@previous_year} #{old_plan.carrier_profile.legal_name} plan hios_id #{old_plan.hios_id} renewed with New #{@current_year} #{new_plan.carrier_profile.legal_name} plan hios_id: #{new_plan.hios_id}" unless Rails.env.test?
            else
              puts "Old #{@previous_year}  plan hios_id #{old_hios_id}-#{new_plan.csr_variant_id} not present." unless Rails.env.test?
            end
          end
        end
      end
    end
    # for scenarios where plan cross walk templates were not provided because
    # there were no plans retired or no new plans present for the renewing year.
    plan_mapping_hash = { "2017" => "2018", "2018" => "2019", "2019" => "2020", "2020" => "2021", "2021" => "2022"}
    plan_mapping_hash.each do |previous_year, current_year|
      old_plans = Plan.where(active_year: previous_year, renewal_plan_id: nil)
      old_plans.each do |old_plan|
        new_plan = Plan.where(active_year: current_year, hios_base_id: old_plan.hios_base_id, csr_variant_id: old_plan.csr_variant_id).first
        if new_plan.present? && old_plan.renewal_plan_id.nil?
          old_plan.renewal_plan_id = new_plan.id
          old_plan.save
          puts "Old #{old_plan.active_year} #{old_plan.carrier_profile.legal_name} plan hios_id #{old_plan.hios_id} renewed with New #{new_plan.active_year} #{new_plan.carrier_profile.legal_name} plan hios_id: #{new_plan.hios_id}" unless Rails.env.test?
        end
      end
    end
  end

  def process_products(cross_walks)
    cross_walks.each do |row|
      old_hios_id = if row["plan_id_#{@previous_year}_hios".to_sym].present?
        row["plan_id_#{@previous_year}_hios".to_sym]
      else
        row["plan_id_cy".to_sym]
      end.squish
      new_hios_id = if row["plan_id_#{@current_year}_hios".to_sym].present?
        row["plan_id_#{@current_year}_hios".to_sym]
      else
        row["plan_id_fy".to_sym]
      end.squish
      is_this_plan_catastrophic_or_child_only_plan = row[:is_this_plan_catastrophic_or_child_only_plan]&.squish&.downcase
      cat_hios_id = row["plan_id_#{@current_year}_for_enrollees_aging_off_catastrophic_or_child_only_plan".to_sym]&.squish
      cat_hios_id ||= row[:plan_id_for_enrollees_aging_off_catastrophic_or_child_only_plan_fy]
      new_products =  ::BenefitMarkets::Products::Product.where(
        hios_id: /#{new_hios_id}/
      ).by_year(@current_year)

      # to handle cases when business provides us with a renewal mapping
      # and then updates the template to say that the old plan got retired with no new mapping.
      if new_hios_id.blank?
        old_products = ::BenefitMarkets::Products::Product.where(
          hios_id: /#{old_hios_id}/
        ).by_year(@previous_year)
        old_products.each do |old_product|
          old_product.update(renewal_product_id: nil)
          puts "#{@previous_year} #{old_product.carrier_profile.legal_name} #{old_product.benefit_market_kind} product hios_id #{old_product.hios_id} retired" unless Rails.env.test?
        end
      else
        new_products.each do |new_product|
          if new_product.present? && new_product.csr_variant_id != "00"
            old_product = ::BenefitMarkets::Products::Product.where(
              hios_id: /#{old_hios_id}/,
              csr_variant_id: /#{new_product.csr_variant_id}/,
              benefit_market_kind: new_product.benefit_market_kind
            ).by_year(@previous_year).first
            if old_product.present?
              old_product.update(renewal_product_id: new_product.id)
              if is_this_plan_catastrophic_or_child_only_plan == "yes" && new_product.csr_variant_id == "01" && new_product.kind.to_s == "health"
                cat_age_off_renewal_product = ::BenefitMarkets::Products::Product.where(
                  hios_id: /#{cat_hios_id}/, csr_variant_id: "01"
                ).by_year(@current_year).first
                old_product.update(catastrophic_age_off_product_id: cat_age_off_renewal_product.id)
                puts "Successfully mapped #{@previous_year} #{old_product.carrier_profile.legal_name} cat age off product with hios_id #{old_product.hios_id} to #{@current_year} #{cat_age_off_renewal_product.carrier_profile.legal_name} product_hios_id: #{cat_age_off_renewal_product.hios_id}" unless Rails.env.test?
              end
              puts "#{@previous_year} #{old_product.carrier_profile.legal_name} #{old_product.benefit_market_kind} product hios_id #{old_product.hios_id} renewed with #{@current_year} #{new_product.carrier_profile.legal_name} #{new_product.benefit_market_kind} product hios_id: #{new_product.hios_id}" unless Rails.env.test?
            else
              puts "#{@previous_year} #{new_product.benefit_market_kind} product hios_id #{old_hios_id}-#{new_product.csr_variant_id} not present." unless Rails.env.test?
            end
          end
        end
      end
    end
    # for scenarios where plan cross walk templates were not provided because
    # there were no plans retired or no new plans present for the renewing year.
    product_mapping_hash = { "2017" => "2018", "2018" => "2019", "2019" => "2020", "2020" => "2021", "2021" => "2022"}
    product_mapping_hash.each do |previous_year, current_year|
      old_products = ::BenefitMarkets::Products::Product.where(
        renewal_product_id: nil
      ).by_year(previous_year)
      old_products.each do |old_product|
        new_product = ::BenefitMarkets::Products::Product.where(
          hios_base_id: old_product.hios_base_id,
          csr_variant_id: old_product.csr_variant_id,
          benefit_market_kind: old_product.benefit_market_kind
        ).by_year(current_year).first
        if new_product.present? && old_product.renewal_product_id.nil?
          old_product.renewal_product_id = new_product.id
          old_product.save
          puts "#{old_product.active_year} #{old_product.carrier_profile.legal_name} #{old_product.benefit_market_kind} product hios_id #{old_product.hios_id} renewed with #{new_product.active_year} #{new_product.carrier_profile.legal_name} #{new_product.benefit_market_kind} product hios_id: #{new_product.hios_id}" unless Rails.env.test?
        end
      end
    end
  end
end

# namespace :xml do
#   task :plan_cross_walk, [:file] => :environment do |task,args|

#     files = Dir.glob(File.join(Rails.root, "db/seedfiles/plan_xmls/master_xml", "**", "*.xlsx"))
#     files.each do |file_path|
#       @file_path = file_path

#       set_data

#       puts "*"*80
#       puts "processing file: #{@file_name} \n"
#       puts "*"*80

#       sheets = ["IVL HIOS Plan Crosswalk", "SHOP HIOS Plan Crosswalk"]
#       # sheets = ["SHOP HIOS Plan Crosswalk"]

#       sheets.each do |sheet|
#         puts "#{previous_year}-#{current_year} Plan mapping started. (#{sheet}) \n"
#         set_sheet_data(sheet)
#         (@first_row..@last_row).each do |row_number| # update renewal plan_ids
#           @row_data = @sheet_data.row(row_number)
#           set_plan_variables
#           if @new_hios_id.present?
#             find_old_plan_and_update_renewal_plan_id
#           else
#             puts "#{@carrier} plan with #{headers[1]} : #{@old_hios_id} is retired."
#             @rejected_hios_ids_list << @old_hios_id
#           end
#         end
#         puts "#{previous_year}-#{current_year} Plan mapping completed. (#{sheet}) \n"
#         puts "*"*80
#       end

#       puts "#{previous_year}-#{current_year} Plan carry over started.\n"
#       find_and_update_carry_over_plans
#       puts "#{previous_year}-#{current_year} Plan carry over completed.\n"
#       puts "*"*80
#     end

#   end

#   def previous_year
#     @year - 1
#   end

#   def current_year
#     @year
#   end

#   def old_plan_hios_ids
#     @old_plans ||= Plan.where(active_year: previous_year).map(&:hios_id)
#   end

#   def set_plan_variables
#     if @sheet == "SHOP HIOS Plan Crosswalk" && current_year == 2017
#       @carrier, @old_hios_id, @old_plan_name, @new_hios_id, @new_plan_name = @row_data[0], @row_data[1], @row_data[2], @row_data[4], @row_data[5]
#     else
#       @carrier, @old_hios_id, @old_plan_name, @new_hios_id, @new_plan_name = @row_data
#     end
#   end

#   def calculate_last_row_number
#     if current_year == 2016
#       @sheet == "IVL HIOS Plan Crosswalk" ? @sheet_data.last_row : 118
#     else
#       @sheet_data.last_row
#     end
#   end

#   def by_hios_id_and_active_year(hios_id, year)
#     Plan.where(hios_id: /#{hios_id}/, active_year: year)
#   end

#   def by_hios_id_active_year_and_csr_varaint_id(hios_id, year, csr_variant_id)
#     Plan.where(hios_id: /#{hios_id}/, active_year: year, csr_variant_id: /#{csr_variant_id}/)
#   end

#   def set_sheet_data(sheet)
#     @sheet = sheet
#     @sheet_data = @result.sheet(@sheet)
#     @headers = @sheet_data.row(1)
#     @last_row = calculate_last_row_number
#     @first_row = 1
#   end

#   def find_old_plan_and_update_renewal_plan_id
#     new_plans = by_hios_id_and_active_year(@new_hios_id.squish, current_year)
#     new_plans.each do |new_plan|
#       if new_plan.present? && new_plan.csr_variant_id != "00"
#         old_plan = by_hios_id_active_year_and_csr_varaint_id(@old_hios_id.squish, previous_year, new_plan.csr_variant_id).first
#         if old_plan.present?
#           old_plan.update(renewal_plan_id: new_plan.id)
#           puts "Old #{previous_year} plan hios_id #{old_plan.hios_id} renewed with New #{current_year} plan hios_id: #{new_plan.hios_id}"
#           @updated_hios_ids_list << old_plan.hios_id
#         else
#           puts "Old #{previous_year} plan hios_id #{@old_hios_id}-#{new_plan.csr_variant_id} not present."
#         end
#       end
#     end
#   end

#   def set_data
#     @file_path_array = @file_path.split("/")
#     @year = @file_path_array[-2].to_i # Retrieve the year of the master xml file you are uploading
#     @file_name = @file_path_array.last
#     @result = Roo::Spreadsheet.open(@file_path)
#     @updated_hios_ids_list = []
#     @rejected_hios_ids_list = []
#   end

#   def find_and_update_carry_over_plans
#     if previous_year == 2015
#       # for 2016 aetna cross walk
#       @rejected_hios_ids_list << ["77422DC0060002", "77422DC0060004", "77422DC0060005", "77422DC0060006", "77422DC0060008", "77422DC0060010"]
#     end
#     @old_plan_hios_ids = old_plan_hios_ids.map { |str| str[0..13] }.uniq
#     @updated_hios_ids_list = @updated_hios_ids_list.map { |str| str[0..13] }.uniq
#     @no_change_in_hios_ids = @old_plan_hios_ids - (@updated_hios_ids_list + @rejected_hios_ids_list)
#     @no_change_in_hios_ids = @no_change_in_hios_ids.uniq
#     @no_change_in_hios_ids.each do |hios_id|
#       new_plans = by_hios_id_and_active_year(hios_id.squish, current_year)
#       new_plans.each do |new_plan|
#         old_plan = by_hios_id_active_year_and_csr_varaint_id(hios_id.squish, previous_year, new_plan.csr_variant_id).first
#         if old_plan.present? && new_plan.present? && new_plan.csr_variant_id != "00"
#           old_plan.update(renewal_plan_id: new_plan.id)
#           puts "Old #{previous_year} plan hios_id #{old_plan.hios_id} carry overed with New #{current_year} plan hios_id: #{new_plan.hios_id}"
#         else
#           puts " plan not present : #{hios_id}"
#         end
#       end
#     end
#   end

# end
