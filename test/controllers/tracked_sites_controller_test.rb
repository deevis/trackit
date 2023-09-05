require 'test_helper'

class TrackedSitesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @tracked_site = tracked_sites(:one)
  end

  test "should get index" do
    get tracked_sites_url
    assert_response :success
  end

  test "should get new" do
    get new_tracked_site_url
    assert_response :success
  end

  test "should create tracked_site" do
    assert_difference('TrackedSite.count') do
      post tracked_sites_url, params: { tracked_site: { category: @tracked_site.category, name: @tracked_site.name, sub_category: @tracked_site.sub_category, url: @tracked_site.url } }
    end

    assert_redirected_to tracked_site_url(TrackedSite.last)
  end

  test "should show tracked_site" do
    get tracked_site_url(@tracked_site)
    assert_response :success
  end

  test "should get edit" do
    get edit_tracked_site_url(@tracked_site)
    assert_response :success
  end

  test "should update tracked_site" do
    patch tracked_site_url(@tracked_site), params: { tracked_site: { category: @tracked_site.category, name: @tracked_site.name, sub_category: @tracked_site.sub_category, url: @tracked_site.url } }
    assert_redirected_to tracked_site_url(@tracked_site)
  end

  test "should destroy tracked_site" do
    assert_difference('TrackedSite.count', -1) do
      delete tracked_site_url(@tracked_site)
    end

    assert_redirected_to tracked_sites_url
  end
end
