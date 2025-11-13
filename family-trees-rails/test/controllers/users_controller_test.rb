require "test_helper"

class UsersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    sign_in @user
  end

  test "should get index" do
    get users_url
    assert_response :success
  end

  test "should show user" do
    get user_url(@user)
    assert_response :success
  end

  test "should get edit for own profile" do
    get edit_user_url(@user)
    assert_response :success
  end

  test "should not get edit for other user profile" do
    other_user = users(:two)
    get edit_user_url(other_user)
    assert_redirected_to root_path
  end

  test "should update own profile" do
    patch user_url(@user), params: { user: { first_name: "Updated", last_name: @user.last_name, birthday: @user.birthday, cell: @user.cell, cityborn: @user.cityborn, citycurrent: @user.citycurrent, date_died: @user.date_died, gender: @user.gender, stateborn: @user.stateborn, statecurrent: @user.statecurrent } }
    assert_redirected_to user_url(@user)
    @user.reload
    assert_equal "Updated", @user.first_name
  end

  test "should not update other user profile" do
    other_user = users(:two)
    patch user_url(other_user), params: { user: { first_name: "Hacked", last_name: other_user.last_name } }
    assert_redirected_to root_path
    other_user.reload
    assert_not_equal "Hacked", other_user.first_name
  end
end
