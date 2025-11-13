require "test_helper"

class RelationshipsControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get relationships_index_url
    assert_response :success
  end

  test "should get new" do
    get relationships_new_url
    assert_response :success
  end

  test "should get create" do
    get relationships_create_url
    assert_response :success
  end

  test "should get edit" do
    get relationships_edit_url
    assert_response :success
  end

  test "should get update" do
    get relationships_update_url
    assert_response :success
  end

  test "should get destroy" do
    get relationships_destroy_url
    assert_response :success
  end
end
