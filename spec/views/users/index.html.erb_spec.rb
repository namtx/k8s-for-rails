require 'rails_helper'

RSpec.describe "users/index", type: :view do
  before(:each) do
    assign(:users, [
      User.create!(
        last_name: "Last Name",
        first_name: "First Name",
        email: "Email"
      ),
      User.create!(
        last_name: "Last Name",
        first_name: "First Name",
        email: "Email"
      )
    ])
  end

  it "renders a list of users" do
    render
    assert_select "tr>td", text: "Last Name".to_s, count: 2
    assert_select "tr>td", text: "First Name".to_s, count: 2
    assert_select "tr>td", text: "Email".to_s, count: 2
  end
end
