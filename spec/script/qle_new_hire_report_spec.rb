require "rails_helper"

describe "ProjectedEligibilityNotice_1" do
  before do
    DatabaseCleaner.clean
  end

  before(:each) do
    invoke_qle_script
    @file = "#{Rails.root}/sep_newhire_enrollment_report.csv"
  end

  it "creates csv file" do
    file_context = CSV.read(@file)
    expect(file_context.size).to be > 0
  end

  it "returns correct fields" do
    CSV.foreach(@file, :headers => true) do |csv|
      expect(csv).to eq   data = ["Employer Name", "Employer FEIN", "Employer Plan Year Begin", "Enrollment Group ID", "Plan Selected On",
                                  "Benefit Begin Date", "Coverage Kind", "Enrollment Status", "Total Premium", "Employer Contribution", 
                                  "Plan HIOS ID", "Plan Name", "Carrier Name", "Plan Type (HMS/PPO/etc.)", "Plan metal level", "New Hire/SEP", 
                                  "New Hire/SEP (Date)", "Subscriber HBX ID", "Subscriber SSN", "Subscriber DOB", "Subscriber Gender", 
                                  "Subscriber Premium", "Subscriber First Name", "Subscriber Middle Name", "Subscriber Last Name", "Subscriber Zip", 
                                  "SELF (only one option)", "Subscriber Premium"]

                                  8.times{ |i|
                                    data += [
                                      "Dep#{i+1} HBX ID",
                                      "Dep#{i+1} SSN",
                                      "Dep#{i+1} DOB",
                                      "Dep#{i+1} Gender ",
                                      "Dep#{i+1} Premium",
                                      "Dep#{i+1} First Name ",
                                      "Dep#{i+1} Middle Name",
                                      "Dep#{i+1} Last Name",
                                      "Dep#{i+1} Zip",
                                      "Dep#{i+1} Relationship",
                                      "Dep#{i+1} Premium"
                                    ]
                                  }
                                  data
    end
  end

  after(:all) do
    FileUtils.rm_f("#{Rails.root.to_s}/sep_newhire_enrollment_report.csv")
  end
end

private

def invoke_qle_script
  ARGV[0] = "6/01/2019"
  ARGV[1] = "7/01/2019"
  qle_new_hire_report_script = File.join(Rails.root, "script/qle_new_hire_report.rb")
  load qle_new_hire_report_script
end