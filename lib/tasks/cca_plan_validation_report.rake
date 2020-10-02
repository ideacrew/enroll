# frozen_string_literal: true

# This rake tasks should be run to generate reports after plans loading.
# To generate all reports please use this rake command: RAILS_ENV=production bundle exec rake plan_validation:reports["2019-12-01"]
require 'rubyXL'
require 'rubyXL/convenience_methods'

namespace :cca_plan_validation do

  def generate_excel(headers, worksheet)
    h = 0
    headers.each do |header|
      worksheet.add_cell(0, h, header)
      h += 1
    end
  end

  def generate_data(worksheet, data, count)
    j = 0
    data.each do |info|
      worksheet.add_cell(count, j, info)
      j += 1
    end
    worksheet
  end

  def issuer_hios_ids
    profiles.flat_map(&:issuer_hios_ids).map(&:to_i)
  end

  def profiles
    BenefitSponsors::Organizations::ExemptOrganization.issuer_profiles.map(&:profiles).flatten
  end

  def products(year)
    ::BenefitMarkets::Products::Product.by_year(year)
  end

  desc "reports generation after plan loading"
  task :reports, [:active_date] => :environment do |_task, args|
    puts "Reports generation started" unless Rails.env.test?
    active_date = args[:active_date].to_date
    active_year = active_date.year
    previous_year = active_year - 1
    workbook = RubyXL::Workbook.new

    #Report1: Details about Plan Count by Carrier, Coverage and Tier
    worksheet = workbook[0]
    worksheet.sheet_name = 'Report1'
    headers = %w[PlanYearId CarrierId CarrierName PlanTypeCode Tier Count]
    generate_excel(headers, worksheet)
    a = 1
    products(active_year).all.each do |product|
      active_year = product.active_year
      carrier_id = product.hios_id[0..4]
      carrier_name = product.issuer_profile.abbrev
      plan_type_code = product.kind == :health ? "QHP" : "QDP"
      tier = product.metal_level_kind.to_s
      product_count = products(active_year).where(hios_id: /#{carrier_id}/i, metal_level_kind: tier).count
      data = [active_year, carrier_id, carrier_name, plan_type_code, tier, product_count]
      generate_data(worksheet, data, a)
      a += 1
    rescue StandardError
      puts "Report1 Plan validation issue for product_id: #{product.id}"
    end
    puts "Successfully generated 1st Plan validation report for Plan Count"

    #Report2: Rating Area and Age Based Plan Rate Sum
    worksheet2 = workbook.add_worksheet('Report2')
    headers = %w[PlanYearId CarrierId CarrierName RatingArea Age Sum]
    generate_excel(headers, worksheet2)
    b = 1
    rating_area_ids = ::BenefitMarkets::Locations::RatingArea.where(active_year: active_year).inject({}) do |data, ra|
      data[ra.id.to_s] = ra.exchange_provided_code
      data
    end
    issuer_hios_ids.each do |issuer_hios_id|
      issuer_products = products(active_year).where(hios_id: /#{issuer_hios_id}/)
      rating_area_ids.each do |rating_area_key, rating_area_value|
        premium_tables = issuer_products.map(&:premium_tables).flatten.select do |prem_tab|
          start_date = prem_tab.effective_period.min.to_date
          end_date = prem_tab.effective_period.max.to_date
          (start_date..end_date).cover?(active_date) && prem_tab.rating_area_id.to_s == rating_area_key
        end
        (0..120).each do |value|
          age = case value
                when 0..14
                  14
                when 64..120
                  64
                else
                  value
                end
          age_cost = premium_tables.map(&:premium_tuples).flatten.select{|tuple| tuple.age == age}.map(&:cost).sum
          carrier_name = issuer_products.first.issuer_profile.legal_name
          ra_val = rating_area_value.gsub("R-MA00", "Rating Area ")
          data = [active_year, issuer_hios_id, carrier_name, ra_val, value, age_cost.round(2).to_s]
          generate_data(worksheet2, data, b)
          b += 1
        rescue StandardError
          puts "Report2 Plan validation issue for issuer_hios_id: #{issuer_hios_id}"
        end
      end
    end
    puts "Successfully generated 2nd Plan validation report for Rating Area"

    #Report3: Service Area based count of Counties, Zip Codes and Plans
    worksheet3 = workbook.add_worksheet('Report3')
    headers = %w[PlanYearId CarrierId CarrierName ServiceAreaCode PlanCount County_Count Zip_Count]
    generate_excel(headers, worksheet3)
    c = 1
    all_county_zip_ids = products(active_year).map(&:service_area).map(&:county_zip_ids).flatten.uniq
    issuer_hios_ids.each do |issuer_hios_id|
      issuer_products = products(active_year).where(hios_id: /#{issuer_hios_id}/)
      grouped_products = issuer_products.group_by(&:service_area)
      grouped_products.each do |service_area, products|
        if service_area.covered_states == ["MA"]
          county_zip_ids = ::BenefitMarkets::Locations::CountyZip.where(:id.in => all_county_zip_ids)
        else
          ids = service_area.county_zip_ids.flatten.uniq
          county_zip_ids = ::BenefitMarkets::Locations::CountyZip.where(:id.in => ids)
        end
        county_count = county_zip_ids.map(&:county_name).uniq.size
        zip_count = county_zip_ids.map(&:zip).uniq.size
        carrier_name = products.first.issuer_profile.legal_name
        data = [active_year, issuer_hios_id, carrier_name, service_area.issuer_provided_code, products.size, county_count, zip_count]
        generate_data(worksheet3, data, c)
        c += 1
      rescue StandardError
        puts "Report3 Plan validation issue for issuer_hios_id: #{issuer_hios_id}"
      end
    end
    puts "Successfully generated 3rd Plan validation report for Counties"

    #Report4: PlanYearId CarrierId CarrierName GroupSizeSum GroupSizeFactorSum
    worksheet4 = workbook.add_worksheet('Report4')
    headers = %w[PlanYearId CarrierId CarrierName GroupSizeSum GroupSizeFactorSum]
    generate_excel(headers, worksheet4)
    d = 1
    profiles.each do |profile|
      carrier_name = profile.abbrev
      profile_id = profile.id.to_s
      profile.issuer_hios_ids.each do |issuer_hios_id|
        group_sizes = BenefitMarkets::Products::ActuarialFactors::GroupSizeActuarialFactor.all.where(active_year: active_year, issuer_profile_id: profile_id)
        group_sizes.each do |group_size|
          group_size_sum = group_size.actuarial_factor_entries.map(&:factor_key).flatten.inject(0) do |sum,i|
            value = i.to_i
            sum + value
          end
          group_size_factor_sum = group_size.actuarial_factor_entries.map(&:factor_value).flatten.inject(0) { |sum,i| sum + i }
          data = [active_year, issuer_hios_id, carrier_name, group_size_sum, group_size_factor_sum.round(3).to_s]
          generate_data(worksheet4, data, d)
          d += 1
        rescue StandardError
          puts "Report4 Plan validation issue for issuer_hios_id: #{issuer_hios_id}"
        end
      end
    end
    puts "Successfully generated 4th Plan validation report for Group Size"

    #Report5: Planyearid CarrierId CarrierName GroupSizeSum ParticipationRateSum
    worksheet5 = workbook.add_worksheet('Report5')
    headers = %w[PlanYearId CarrierId CarrierName GroupSizeSum ParticipationRateSum]
    generate_excel(headers, worksheet5)
    e = 1
    profiles.each do |profile|
      carrier_name = profile.abbrev
      profile_id = profile.id.to_s
      profile.issuer_hios_ids.each do |issuer_hios_id|
        part_rates = ::BenefitMarkets::Products::ActuarialFactors::ParticipationRateActuarialFactor.all.where(active_year: active_year, issuer_profile_id: profile_id)
        part_rates.each do |part_rate|
          group_size_sum = part_rate.actuarial_factor_entries.map(&:factor_key).flatten.inject(0) do |sum,i|
            value = i.to_i
            sum + value
          end
          participation_rate_sum = part_rate.actuarial_factor_entries.map(&:factor_value).flatten.inject(0) { |sum,i| sum + i }
          data = [active_year, issuer_hios_id, carrier_name, group_size_sum, participation_rate_sum.round(2).to_s]
          generate_data(worksheet5, data, e)
          e += 1
        rescue StandardError
          puts "Report5 Plan validation issue for issuer_hios_id: #{issuer_hios_id}"
        end
      end
    end
    puts "Successfully generated 5th Plan validation report for Participation Rate"

    #Report6: SIC Codes Count & Rate Factor Sum
    worksheet6 = workbook.add_worksheet('Report6')
    headers = %w[PlanYearId CarrierId CarrierName SIC_Count SICRateSum]
    generate_excel(headers, worksheet6)
    f = 1
    profiles.each do |profile|
      carrier_name = profile.abbrev
      profile_id = profile.id.to_s
      profile.issuer_hios_ids.each do |issuer_hios_id|
        sic_codes = ::BenefitMarkets::Products::ActuarialFactors::SicActuarialFactor.all.where(active_year: active_year, issuer_profile_id: profile_id)
        sic_codes.all.each do |sic_code|
          sic_count = sic_code.actuarial_factor_entries.count
          sic_rate_sum = sic_code.actuarial_factor_entries.map(&:factor_value).flatten.inject(0) { |sum,i| sum + i }
          data = [active_year, issuer_hios_id, carrier_name, sic_count, sic_rate_sum.round(2).to_s]
          generate_data(worksheet6, data, f)
          f += 1
        rescue StandardError
          puts "plan validation issue for issuer_hios_id: #{issuer_hios_id}"
        end
      end
    end
    puts "Successfully generated 6th Plan validation report for SIC Codes"

    #Report7: CarrierId CarrierName ProductModel PlanCount
    worksheet7 = workbook.add_worksheet('Report7')
    headers = %w[CarrierId CarrierName ProductModel PlanCount]
    generate_excel(headers, worksheet7)
    g = 1
    issuer_hios_ids.each do |issuer_hios_id|
      products = products(active_year).where(hios_id: /#{issuer_hios_id}/)
      carrier_name = products.first.issuer_profile.abbrev
      offerings = { metal_level: "Horizontal Offering", single_issuer: "Vertical Offering", single_product: "Sole Source Offering" }
      offerings.each do |product_package_kind, offering_type|
        product_count = products.where(:product_package_kinds.in => [product_package_kind]).size
        data = [issuer_hios_id, carrier_name, offering_type, product_count]
        generate_data(worksheet7, data, g)
        g += 1
      rescue StandardError
        puts "plan validation issue for issuer_hios_id: #{issuer_hios_id}"
      end
    end
    puts "Successfully generated 7th Plan validation report for Product Model"

    #Report8: CarrierId CarrierName HIOS_ID Renewal_HIOS_ID
    worksheet8 = workbook.add_worksheet('Report8')
    headers = %w[CarrierId CarrierName HIOS_ID Renewal_HIOS_ID]
    generate_excel(headers, worksheet8)
    h = 1
    products(previous_year).each do |product|
      carrier_id = product.hios_id[0..4]
      carrier_name = product.issuer_profile.legal_name
      hios_id = product.hios_id
      renewal_hios_id = product.try(:renewal_product).try(:hios_id)
      data = [carrier_id, carrier_name, hios_id, renewal_hios_id]
      generate_data(worksheet8, data, h)
      h += 1
    rescue StandardError
      puts "plan validation issue for Product_id: #{product.id}"
    end
    puts "Successfully generated 8th Plan validation report for HIOS ID's"

    #Report9: Plans with SuperGroupIDs"
    worksheet9 = workbook.add_worksheet('Report9')
    headers = %w[PlanYearId CarrierId CarrierName HIOS_Plan_ID SG_ID]
    generate_excel(headers, worksheet9)
    i = 1
    products(active_year).each do |product|
      carrier_id = product.hios_id[0..4]
      carrier_name = product.issuer_profile.legal_name
      hios_id = product.hios_id
      issuer_assigned_id = product.try(:issuer_assigned_id)
      data = [active_year, carrier_id, carrier_name, hios_id, issuer_assigned_id]
      generate_data(worksheet9, data, i)
      i += 1
    rescue StandardError
      puts "plan validation issue for Product_id: #{product.id}"
    end
    puts "Successfully generated 9th Plan validation report for Super Group ID's"

    current_date = Date.today.strftime("%Y_%m_%d")
    workbook.write("#{Rails.root}/CCA_PlanLoadValidation_Report_EA_#{current_date}.xlsx")
  end
end
