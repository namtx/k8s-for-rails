require 'rails_helper'

RSpec.describe "users/show", type: :view do
  before(:each) do
    @user = assign(:user, User.create!(
      last_name: "Last Name",
      first_name: "First Name",
      email: "Email"
    ))
  end

  it "renders attributes in <p>" do
    render
    expect(rendered).to match(/Last Name/)
    expect(rendered).to match(/First Name/)
    expect(rendered).to match(/Email/)
  end
end
