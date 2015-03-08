namespace :seed do
  desc "Load the plan data"
  task :plans => :environment do
    Plan.delete_all
    plan_file = File.open("db/seedfiles/plans.json", "r")
    data = plan_file.read
    plan_file.close
    plan_data = JSON.load(data)
    plan_data.each do |pd|
      Plan.create!(pd)
    end
  end
end
