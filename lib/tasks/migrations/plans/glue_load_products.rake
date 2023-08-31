# This rake task generates an array of JSON objects representing all Product data in Enroll for the given year
# The output file is used to load Product data into Glue

# Examples
# RAILS_ENV=production bundle exec rake seed:load_products[2024]

namespace :seed do
  desc 'Generate Product JSON Dump for Loading into Glue'
  task :load_products, [:year] => :environment do |task, args|

    @json_file_name = Rails.root.join("#{args[:year]}_plans.json")
    @error_file_name = Rails.root.join("#{args[:year]}_plans_error.txt")
    if File.exist?(@json_file_name)
      puts "File #{@json_file_name} already exists!"
      abort
    end

    def write_to_json_file(content)
      if !File.exist?(@json_file_name)
        File.write(@json_file_name, content)
      else
        File.open(@json_file_name, 'a') do |f|
          f.write content
        end
      end
    end

    def write_to_error_file(content)
      if !File.exist?(@error_file_name)
        File.write(@error_file_name, content)
      else
        File.open(@error_file_name, 'a') do |f|
          f.write content
        end
      end
    end

    def build_premium_tables(premium_tables)
      results = premium_tables
      premium_tables.select{|pm| pm[:age] == 14 }.each do |pt|
        (0..13).each do |age_number|
          results << {age: age_number, rate_start_date: pt[:rate_start_date], rate_end_date: pt[:rate_end_date], amount: pt[:amount]}
        end
      end
      premium_tables.select{|pm| pm[:age] == 64 }.each do |pt|
        (65..120).each do |age_number|
          results << {age: age_number, rate_start_date: pt[:rate_start_date], rate_end_date: pt[:rate_end_date], amount: pt[:amount]}
        end
      end
      results
    end

    def dump_product_for_enroll(product)
      product_json = {
        id: product.id.to_s,
        name: product.title,
        hios_plan_id: product.hios_id,
        hios_base_id: product.hios_base_id,
        csr_variant_id: product.csr_variant_id,
        ehb: product.ehb.nil? ? "0.0" : product.ehb.to_s,
        year: product.active_year,
        carrier_id: product.issuer_profile_id.to_s,
        fein: fein(product),
        metal_level: product.metal_level_kind.to_s,
        coverage_type: product.kind.to_s,
        renewal_plan_id: product.renewal_product_id,
        renewal_plan_hios_id: product.try(:renewal_product).try(:hios_id),
        minimum_age: 0,
        maximum_age: 120,
        market_type: product.benefit_market_kind == :aca_individual ? 'individual' : 'shop'
      }
      premium_tables = []
      product.premium_tables.each do |premium_table|
        premium_table.premium_tuples.each do |premium_tuple|
          if (premium_tuple.age < 65) && (premium_tuple.age > 13)
            premium_tables << {
              :age => premium_tuple.age,
              :rate_start_date => premium_table.effective_period.min.to_date,
              :rate_end_date => premium_table.effective_period.max.to_date,
              :amount => premium_tuple.cost
            }
          end
        end
      end

      output = JSON.dump(product_json.merge({:premium_tables => build_premium_tables(premium_tables).uniq}))
      write_to_json_file(output)
    rescue Exception => e
      error_message = "Error dumping product: #{product.hios_id}, #{e.message}"
      write_to_error_file(error_message)
      nil
    end

    def fein(product)
      fein = Rails.cache.fetch("#{product.active_year}_#{product.id}", expires_in: 1.month) do
        carrier_profile_id = CarrierProfile.find_by_legal_name(product.issuer_profile.legal_name)
        CarrierProfile.find(carrier_profile_id).fein if carrier_profile_id.present?
      end

      if fein.nil? && product.issuer_profile.present?
        fein = product.issuer_profile.fein
      end
      return fein if fein.present?

      raise StandardError.new
    rescue Exception => _e
      error_message = "Error finding fein for product: #{product.hios_id}\n"
      write_to_error_file(error_message)
      nil
    end

    write_to_json_file("[\n")
    products = ::BenefitMarkets::Products::Product.by_year(args[:year]).where(:benefit_market_kind.in => [:aca_shop, :aca_individual])
    products.each_with_index do |product, index| 
      result = dump_product_for_enroll(product)
      write_to_json_file("\n,\n") if result.present? && products.count != index + 1
    end
    write_to_json_file("]")

    unless Rails.env.test?
      puts "Rake complete!"
      puts "Product dump can be found at #{@json_file_name}"
      puts "Error log can be found at #{@error_file_name}"
    end
  end
end