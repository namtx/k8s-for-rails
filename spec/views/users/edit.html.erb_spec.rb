require 'rails_helper'

RSpec.describe "users/edit", type: :view do
  before(:each) do
    @user = assign(:user, User.create!(
      last_name: "MyString",
      first_name: "MyString",
      email: "MyString"
    ))
  end

  it "renders the edit user form" do
    render

    assert_select "form[action=?][method=?]", user_path(@user), "post" do

      assert_select "input[name=?]", "user[last_name]"

      assert_select "input[name=?]", "user[first_name]"

      assert_select "input[name=?]", "user[email]"
    end
  end
end
