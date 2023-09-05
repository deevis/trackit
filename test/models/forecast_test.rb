# == Schema Information
#
# Table name: forecasts
#
#  id                 :bigint           not null, primary key
#  station_id         :bigint
#  time               :datetime
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  temp_min           :integer
#  temp_max           :integer
#  temp_diff          :integer
#  temp_diff_hours    :integer
#  temp_diff_per_hour :float(24)
#  wind_min           :integer
#  wind_max           :integer
#  wind_diff          :integer
#  wind_diff_hours    :integer
#  wind_diff_per_hour :float(24)
#

require 'test_helper'

class ForecastTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
