# == Schema Information
#
# Table name: tracked_site_data
#
#  id              :bigint           not null, primary key
#  start_time      :datetime
#  end_time        :datetime
#  tracked_site_id :bigint
#  data            :text(4294967295)
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#

require 'test_helper'

class TrackedSiteDatumTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
