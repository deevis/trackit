require "application_system_test_case"

class TrackedSiteProductIndicesTest < ApplicationSystemTestCase
  setup do
    @tracked_site_product_index = tracked_site_product_indices(:one)
  end

  test "visiting the index" do
    visit tracked_site_product_indices_url
    assert_selector "h1", text: "Tracked site product indices"
  end

  test "should create tracked site product index" do
    visit tracked_site_product_indices_url
    click_on "New tracked site product index"

    fill_in "Category", with: @tracked_site_product_index.category
    fill_in "Product index url", with: @tracked_site_product_index.product_index_url
    fill_in "Sub category", with: @tracked_site_product_index.sub_category
    fill_in "Tracked site class", with: @tracked_site_product_index.tracked_site_class
    click_on "Create Tracked site product index"

    assert_text "Tracked site product index was successfully created"
    click_on "Back"
  end

  test "should update Tracked site product index" do
    visit tracked_site_product_index_url(@tracked_site_product_index)
    click_on "Edit this tracked site product index", match: :first

    fill_in "Category", with: @tracked_site_product_index.category
    fill_in "Product index url", with: @tracked_site_product_index.product_index_url
    fill_in "Sub category", with: @tracked_site_product_index.sub_category
    fill_in "Tracked site class", with: @tracked_site_product_index.tracked_site_class
    click_on "Update Tracked site product index"

    assert_text "Tracked site product index was successfully updated"
    click_on "Back"
  end

  test "should destroy Tracked site product index" do
    visit tracked_site_product_index_url(@tracked_site_product_index)
    click_on "Destroy this tracked site product index", match: :first

    assert_text "Tracked site product index was successfully destroyed"
  end
end
