require "test_helper"

class FamilyTreesControllerTest < ActionDispatch::IntegrationTest
  test "should get show" do
    get family_trees_show_url
    assert_response :success
  end
end
