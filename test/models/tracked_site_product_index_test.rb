# == Schema Information
#
# Table name: tracked_site_product_indices
#
#  id                 :bigint           not null, primary key
#  tracked_site_class :string(255)
#  product_index_url  :string(255)
#  category           :string(255)
#  sub_category       :string(255)
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  data               :text(4294967295)
#
require "test_helper"

class TrackedSiteProductIndexTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
