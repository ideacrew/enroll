namespace :dry_run do
  namespace :reports do

    desc "run the renewal report for a given year"
    task :renewals, [:year] => :environment do |_t, args|
      # who should have been renewed
      # who was renewed
      # who was not renewed
    end

    desc "run the determinations report for a given year"
    task :determinations, [:year] => :environment do |_t, args|
      # who should have been determined
      # who was determined
      # who was not determined
    end


    desc "run the notices report for a given year"
    task :notices, [:year] => :environment do |_t, args|
      # who should have been notified with what notice
      # who was notified with what notice
      # who was not notified with what notice
    end

    desc "notices generated for a given date range"
    task :notices_by_dates, [:start_date, :end_date] => :environment do |_t, args|
      start_date = args[:start_date] || Date.today
      end_date = args[:end_date] || Date.today
      file_name = "notices_#{start_date.strftime('%Y_%m_%d')}_#{end_date.strftime('%Y_%m_%d')}.csv"
      title_code_mapping = { 'Welcome to CoverME.gov!' => 'IVLMWE',
                             'Your Plan Enrollment' => 'IVLENR',
                             'Your Eligibility Results - Tax Credit' => 'IVLERA',
                             'Your Eligibility Results - MaineCare or Cub Care' => 'IVLERM',
                             'Your Eligibility Results - Marketplace Health Insurance' => 'IVLERQ',
                             'Your Eligibility Results - Marketplace Insurance' => 'IVLERU',
                             'Open Enrollment - Tax Credit' => 'IVLOEA',
                             'Open Enrollment - Update Your Application' => 'IVLOEM',
                             'Your Eligibility Results - Health Coverage Eligibility' => 'IVLOEQ',
                             'Open Enrollment - Marketplace Insurance' => 'IVLOEU',
                             'Your Eligibility Results Consent or Missing Information Needed' => 'IVLOEG',
                             'Find Out If You Qualify For Health Insurance On CoverME.gov' => 'IVLMAT',
                             'Your Plan Enrollment for 2022' => 'IVLFRE',
                             'Action Needed - Submit Documents' => 'IVLDR0',
                             'Reminder - You Must Submit Documents' => 'IVLDR1',
                             "Don't Forget - You Must Submit Documents" => 'IVLDR2',
                             "Don't Miss the Deadline - You Must Submit Documents" => 'IVLDR3',
                             'Final Notice - You Must Submit Documents' => 'IVLDR4' }
      people = Person.where(:'documents.created_at' => { :$gte => start_date, :$lte => end_date }).to_a
      CSV.open(file_name, 'w+', headers: true) do |csv|
        csv << ['HBX ID', 'Notice Title', 'Notice Code', 'Date']
        people.each do |person|
          documents = person.documents.where(:created_at.gte => start_date,
                                             :created_at.lte => end_date).to_a
          documents.each do |document|
            csv << [person.hbx_id, document.title, title_code_mapping[document.title], document.created_at]
          end
        end
      end
    end

  end
end
