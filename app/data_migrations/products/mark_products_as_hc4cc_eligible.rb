# frozen_string_literal: true

# require File.join(Rails.root, "lib/mongoid_migration_task")

# Marking products and plans as hc4cc eligible by reading data from given csv
class MarkProductsAsHc4ccEligible < MongoidMigrationTask
  def migrate
    file_name = ENV['file_name'].to_s
    CSV.foreach("#{Rails.root}/#{file_name}", headers: true) do |row|
      active_year = row["ActiveYear"]
      hios_id = row["HiosId"]
      csr_variant = row["CsrVarient"]
      next unless hios_id.present?

      hios_base_id = hios_id.split("-").first
      csr_variant_id = csr_variant || hios_id.split("-").last
      csr_variant_id = "" if csr_variant_id.length != 2
      update_product(active_year, hios_base_id, csr_variant_id)
      update_plan(active_year, hios_base_id, csr_variant_id)
      puts "marked Plan/product with hios_id: #{hios_base_id} as Hc4cc Eligible"
    end
  end

  def update_product(year, hios_base_id, csr_variant_id)
    product = BenefitMarkets::Products::Product.all.by_year(year).where(hios_base_id: hios_base_id, csr_variant_id: csr_variant_id).first
    if product.present?
      product.update!(is_hc4cc_plan: true)
    else
      puts "No product found with hios_id: #{hios_base_id}, csr_variant_id: #{csr_variant_id} and year #{year} "
    end
  end

  def update_plan(year, hios_base_id, csr_variant_id)
    plan = Plan.by_active_year(year).where(hios_base_id: hios_base_id, csr_variant_id: csr_variant_id).first
    if plan.present?
      plan.update!(is_hc4cc_plan: true)
    else
      puts "No plan found with hios_id: #{hios_base_id}, csr_variant_id: #{csr_variant_id} and year #{year} "
    end
  end
end