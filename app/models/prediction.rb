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
require 'set'

class Prediction < ApplicationRecord
  belongs_to :station
  belongs_to :forecast

  def self.summarize_for_start_time(predictions)
    min_temp = 99999
    max_temp = -9999
    
    min_wind = 99999
    max_wind = -9999
    start_time = nil
    predictions.each do |p|
      start_time ||= p.start_time
      raise "Got varying start_times but expected same for all" if start_time != p.start_time

      # scan for Temp min/max
      if p.temperature <= min_temp
        min_temp = p.temperature 
      end
      if p.temperature >= max_temp
        max_temp = p.temperature
      end

      # scan for Wind min/max
      if p.wind_speed <= min_wind
        min_wind = p.wind_speed 
      end
      if p.wind_speed >= max_wind
        max_wind = p.wind_speed
      end

    end

    { temp_diff: (max_temp - min_temp), min_temp: min_temp, max_temp: max_temp, 
      wind_diff: (max_wind - min_wind), min_wind: min_wind, max_wind: max_wind,
      actual_temp: predictions.last.temperature,
      actual_wind: predictions.last.wind_speed, 
      observations: predictions.length
    }
  end
end
