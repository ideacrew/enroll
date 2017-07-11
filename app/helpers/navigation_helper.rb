module NavigationHelper
  TABS_WITH_TITLE = {"accountRegistration" => { "title" => "Account Registration", "id" => "accountRegistration", active: true}, "moreAboutYou" => { "title" => "Tell us About Yourself", "id" => "moreAboutYou", active: true }, "householdinfo" => { "title" => "Household Info", "id" => "householdInfo" } }

  def self.getAllTabs
    TABS_WITH_TITLE.map {|tab, tabValue| {"title" => tabValue["title"], "id"=> tabValue["id"], active: tabValue[:active]}}
  end
end
