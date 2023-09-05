# == Schema Information
#
# Table name: predictions
#
#  id               :bigint           not null, primary key
#  forecast_id      :bigint
#  station_id       :bigint
#  start_time       :datetime
#  end_time         :datetime
#  temperature      :integer
#  temperature_unit :string(1)
#  wind_speed       :integer
#  wind_unit        :string(4)
#  wind_direction   :string(4)
#  short_forecast   :string(255)
#  icon             :string(30)
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#

require 'test_helper'

class PredictionTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
