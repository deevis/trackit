require "application_system_test_case"

class TrackedSitesTest < ApplicationSystemTestCase
  setup do
    @tracked_site = tracked_sites(:one)
  end

  test "visiting the index" do
    visit tracked_sites_url
    assert_selector "h1", text: "Tracked Sites"
  end

  test "creating a Tracked site" do
    visit tracked_sites_url
    click_on "New Tracked Site"

    fill_in "Category", with: @tracked_site.category
    fill_in "Name", with: @tracked_site.name
    fill_in "Sub category", with: @tracked_site.sub_category
    fill_in "Url", with: @tracked_site.url
    click_on "Create Tracked site"

    assert_text "Tracked site was successfully created"
    click_on "Back"
  end

  test "updating a Tracked site" do
    visit tracked_sites_url
    click_on "Edit", match: :first

    fill_in "Category", with: @tracked_site.category
    fill_in "Name", with: @tracked_site.name
    fill_in "Sub category", with: @tracked_site.sub_category
    fill_in "Url", with: @tracked_site.url
    click_on "Update Tracked site"

    assert_text "Tracked site was successfully updated"
    click_on "Back"
  end

  test "destroying a Tracked site" do
    visit tracked_sites_url
    page.accept_confirm do
      click_on "Destroy", match: :first
    end

    assert_text "Tracked site was successfully destroyed"
  end
end
