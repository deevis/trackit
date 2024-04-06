require "test_helper"

class TrackedSiteProductIndicesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @tracked_site_product_index = tracked_site_product_indices(:one)
  end

  test "should get index" do
    get tracked_site_product_indices_url
    assert_response :success
  end

  test "should get new" do
    get new_tracked_site_product_index_url
    assert_response :success
  end

  test "should create tracked_site_product_index" do
    assert_difference("TrackedSiteProductIndex.count") do
      post tracked_site_product_indices_url, params: { tracked_site_product_index: { category: @tracked_site_product_index.category, product_index_url: @tracked_site_product_index.product_index_url, sub_category: @tracked_site_product_index.sub_category, tracked_site_class: @tracked_site_product_index.tracked_site_class } }
    end

    assert_redirected_to tracked_site_product_index_url(TrackedSiteProductIndex.last)
  end

  test "should show tracked_site_product_index" do
    get tracked_site_product_index_url(@tracked_site_product_index)
    assert_response :success
  end

  test "should get edit" do
    get edit_tracked_site_product_index_url(@tracked_site_product_index)
    assert_response :success
  end

  test "should update tracked_site_product_index" do
    patch tracked_site_product_index_url(@tracked_site_product_index), params: { tracked_site_product_index: { category: @tracked_site_product_index.category, product_index_url: @tracked_site_product_index.product_index_url, sub_category: @tracked_site_product_index.sub_category, tracked_site_class: @tracked_site_product_index.tracked_site_class } }
    assert_redirected_to tracked_site_product_index_url(@tracked_site_product_index)
  end

  test "should destroy tracked_site_product_index" do
    assert_difference("TrackedSiteProductIndex.count", -1) do
      delete tracked_site_product_index_url(@tracked_site_product_index)
    end

    assert_redirected_to tracked_site_product_indices_url
  end
end
