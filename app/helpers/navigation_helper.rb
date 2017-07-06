module NavigationHelper
  TABS_WITH_TITLE = {"accountRegistration" => { "title" => "Account Registration", "id" => "accountRegistration", active: true}, "moreAboutYou" => { "title" => "Tell us About Yourself", "id" => "moreAboutYou", active: true }, "householdinfo" => { "title" => "Household Info", "id" => "householdInfo" } }

  def self.getAllTabs
    TABS_WITH_TITLE.map {|tab, tabValue| {"title" => tabValue["title"], "id"=> tabValue["id"], active: tabValue[:active]}}
  end

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
