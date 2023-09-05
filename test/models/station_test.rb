# == Schema Information
#
# Table name: stations
#
#  id                  :bigint           not null, primary key
#  name                :string(255)
#  code                :string(255)
#  city                :string(255)
#  state               :string(255)
#  data                :text(4294967295)
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  last_forecast_time  :datetime
#  current_forecast_id :bigint
#

require 'test_helper'

class StationTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
