# Received latest version of kaiser shop plan templates with updated plan count of 28, initial version plan count was 31
# RAILS_ENV=production bundle exec rake remove:kaiser_2019_shop_plans

namespace :remove do
  task :kaiser_2019_shop_plans => :environment do
    Plan.where(active_year: 2019, :"hios_base_id".in => ["94506DC0350029", "94506DC0350030", "94506DC0350031"]).delete_all
    Products::Qhp.where(active_year: 2019, :"standard_component_id".in => ["94506DC0350029", "94506DC0350030", "94506DC0350031"]).delete_all
  end
end

