When(/^I see the (\w+) link$/) do |method|	
  find_link(method)
end


Then(/^the Paper action should not be actionable$/) do
  find_link('Paper')['disabled'].should == 'disabled'
end
