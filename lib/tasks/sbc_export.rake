require 'csv'

namespace :sbc do

  desc "Export Sbc data"
  task :data_export, [:year] => :environment do |task, args|

    field_names  = %w(
        product_name hios_id year identifier title
      )

    file_name = "sbc_export.csv"
    years = args[:year].present? ? [args[:year].to_i] : [2020, 2021]

    CSV.open(file_name, "w", force_quotes: true) do |csv|
      csv << field_names

      years.each do |year|
        ::BenefitMarkets::Products::Product.by_year(year).each do |product|
          csv << [
            product.title,
            product.hios_id,
            product.active_year,
            product&.sbc_document&.identifier,
            product&.sbc_document&.title
          ]
        end
      end
    end
  end
end
