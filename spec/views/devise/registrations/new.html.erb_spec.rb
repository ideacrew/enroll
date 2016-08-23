require 'rails_helper'

RSpec.describe "devise/registrations/new", type: :view do
  context "to have " do
    it "should  have password hints" do
    	render file: "devise/registrations/new.html.erb"
    	[	'Minimum of 8 characters' ,
    		'Must have at least 4 alphabetical characters',
    		'Cannot contain username',
    		'Must include at least one lowercaseletter, one uppercase letter, one digit, and one character that is not a digit or letter or space',
    		'Cannot repeat any character more than 4 times',
    		'Must not repeat consecutive characters more than once'
    		].each do |message|
      	expect(rendered).to have_content(message)
      end
    end
	end
end
