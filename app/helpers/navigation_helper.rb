module NavigationHelper
  TABS_WITH_TITLE = {"accountRegistration" => { "title" => "Account Registration", "id" => "accountRegistration", active: true}, "moreAboutYou" => { "title" => "Tell us About Yourself", "id" => "moreAboutYou", active: true }, "householdinfo" => { "title" => "Household Info", "id" => "householdInfo" } }
  YML_TABS_WITH_TITLE = {"personalInfo" => {"title" => "Personal Info", "id" => "personalInfo"}, "incomeAndCoverageInfo" => {"title" => "Income and Coverage Info", "id" => "incomeAndCoverageInfo"}, "taxInfo" => {"title" => "Tax Info", "id" => "taxInfo", "link" => "/step/1"}, "jobIncome" => {"title" => "Job Income", "id" => "jobIncome", "link" => "/incomes/new"}, "otherIncome" => {"title" => "Other income", "id" => "otherIncome"}, "incomeAdjustments" => {"title" => "Income Adjustments", "id" => "incomeAdjustments", "link"=>"/deductions/new"}, "healthCoverage" => {"title" => "Health Coverage", "id" => "healthCoverage", "link" => "/benefits/new"}, "otherQuestions" => {"title" => "Other Questions", "id" => "otherQuestions"}}

  def self.getAllTabs
    TABS_WITH_TITLE.map {|tab, tabValue| {"title" => tabValue["title"], "id"=> tabValue["id"], active: tabValue[:active]}}
  end

  # def self.getAllYmlTabs
  #   YML_TABS_WITH_TITLE.map {|tab, tabValue| {"title" => tabValue["title"], "id"=> tabValue["id"], "link"=>tabValue["link"]}}
  # end

  def nav_for_applicants
    @application.applicants.inject(raw('')) do |list, applicant|
      if applicant.applicant_validation_complete?
        classes = 'activer list-box step-tabs'
      else
        classes = 'list-box step-tabs'
      end

      list += content_tag :li, class: classes do
        link_to(applicant.person.first_name, edit_financial_assistance_application_applicant_path(@application, applicant))
      end
    end
  end
end
