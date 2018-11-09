#run below to load dummy data for all carriers
#RAILS_ENV=production bundle exec rake dump_dummy:premium_rates action=load_rates start_date='2018-10-01'

#run below to load dummy data only for particular carrier
#RAILS_ENV=production bundle exec rake dump_dummy:premium_rates action=load_rates start_date='2018-10-01' abbrevs="abc,def,ijk"

#run below to cleanup the loaded dummy data
#RAILS_ENV=production bundle exec rake dump_dummy:premium_rates action=cleanup_rates start_date='2018-10-01'

namespace :dump_dummy do
  desc "dump test data and cleanup test data for rates"
  task :premium_rates => :environment do

    start_date = ENV["start_date"]
    abbrevs = ENV["abbrevs"]
    action = ENV["action"]

    fail 'start_date is required' unless start_date.present? unless Rails.env.test?
    fail 'action is required' unless action.present? unless Rails.env.test?

    @issuer_profile_hash = {}
    build_issuer_profile_hash abbrevs
    effective_period = set_quarter_range start_date.to_date

    fail 'empty set for issuer_profile' unless @issuer_profile_hash.present? unless Rails.env.test?

    products = ::BenefitMarkets::Products::Product.all.where(:'issuer_profile_id'.in => @issuer_profile_hash.values)

    if action == "load_rates"
      products.each do |product|
        build_premiums product, effective_period
      end
      puts "loading completed" unless Rails.env.test?
    elsif action == "cleanup_rates"
      products.each do |product|
        cleanup_premiums product, effective_period
      end
      puts "cleanup completed" unless Rails.env.test?
    end
  end
end

private

def self.set_quarter_range(start_date)
  start_date = Time.utc(start_date.year, start_date.month, start_date.day)
  end_date = start_date.months_since(3).days_ago(1)
  (start_date..end_date)
end

def self.build_premiums(product, effective_period)
  pts = product.premium_tables.select {|a| a.effective_period.min == effective_period.min.months_ago(3)}
  pts.each do |pt|
    new_pt = product.premium_tables.create(pt.attributes.except(:_id, :premium_tuples))
    new_pt.effective_period = effective_period
    pt.premium_tuples.each do |tuple|
      new_pt.premium_tuples.create(tuple.attributes.except(:_id, :premium_tables))
    end
    product.save!
    print "." unless Rails.env.test?
  end
end

def self.cleanup_premiums(product, effective_period)
  product.premium_tables.where(:"effective_period.min" => effective_period.min).each(&:delete)
  product.save!
  print "." unless Rails.env.test?
end

def self.build_issuer_profile_hash(abbrevs)
  abbrevs = abbrevs.split(",") if abbrevs
  exempt_organizations = ::BenefitSponsors::Organizations::Organization.issuer_profiles.where(:"profiles.abbrev".in => abbrevs) if abbrevs
  exempt_organizations = ::BenefitSponsors::Organizations::Organization.issuer_profiles if abbrevs.nil?

  exempt_organizations.each do |exempt_organization|
    issuer_profile = exempt_organization.issuer_profile
    @issuer_profile_hash[issuer_profile.abbrev] = issuer_profile.id.to_s
  end
  @issuer_profile_hash
end
