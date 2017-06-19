module NavigationHelper
  TABS_WITH_TITLE = {"accountRegistration" => { "title" => "Account Registration", "id" => "accountRegistration"}, "moreAboutYou" => { "title" => "Tell us About Yourself", "id" => "moreAboutYou" }, "householdinfo" => { "title" => "Household Info", "id" => "householdInfo" } }
  YML_TABS_WITH_TITLE = {"personalInfo" => {"title" => "Personal Info", "id" => "personalInfo"}, "incomeAndCoverageInfo" => {"title" => "Income and Coverage Info", "id" => "incomeAndCoverageInfo"}, "taxInfo" => {"title" => "Tax Info", "id" => "taxInfo", "link" => "/step/1"}, "jobIncome" => {"title" => "Job Income", "id" => "jobIncome", "link" => "/incomes/new"}, "otherIncome" => {"title" => "Other income", "id" => "otherIncome"}, "incomeAdjustments" => {"title" => "Income Adjustments", "id" => "incomeAdjustments", "link"=>"/deductions/new"}, "healthCoverage" => {"title" => "Health Coverage", "id" => "healthCoverage", "link" => "/benefits/new"}, "otherQuestions" => {"title" => "Other Questions", "id" => "otherQuestions"}}

  def self.getAllTabs
    TABS_WITH_TITLE.map {|tab, tabValue| {"title" => tabValue["title"], "id"=> tabValue["id"]}}
  end

  def self.getAllYmlTabs
    YML_TABS_WITH_TITLE.map {|tab, tabValue| {"title" => tabValue["title"], "id"=> tabValue["id"], "link"=>tabValue["link"]}}
  end
end