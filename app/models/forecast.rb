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
#  end_time           :datetime
#  current_temp       :integer
#  current_wind       :integer
#

class Forecast < ApplicationRecord
  belongs_to :station
  has_many :predictions, dependent: :destroy
  before_update :compute_stats
  # after_commit :cleanup_invalid

  def current_prediction
    predictions.order("start_time ASC").first
  end

  def previous_prediction_range(prediction_type = :temp)
    if prediction_type == :temp
      [temp_min, temp_max]
    else
      [wind_min, wind_max]
    end
  end

  def current_statistics
    answer = self.current_temp
    temps = self.predictions_for.map{|p| p.temperature}
    if temps.length > 1
      squared_diffs = temps.inject(0){|a,t| a + (t-answer) * (t-answer)}
      variance = squared_diffs / (temps.length.to_f - 1)
      std_dev = Math.sqrt(variance)
    else
      variance, std_dev = 0, 0
    end
    { temp: answer, min: self.temp_min, max: self.temp_max, 
      sample_count: temps.length, 
      error_variance: variance, error_deviation: std_dev }
  end

  # Return all predictions 
  def predictions_for(start_time = self.time)
    station.predictions.includes(:forecast).joins(:forecast).where(start_time: start_time)
  end

  def self.cleanse_bad_data(temp: -100, dryrun: true)
    Prediction.transaction do 
      result = Prediction.where(temperature: temp).delete_all
      puts "Destroyed #{result} Predictions"
      updated, destroyed = 0,0
      Forecast.where(temp_min: temp).find_each do |f|
        if f.predictions.count > 0
          updated += 1
          f.send(:compute_stats)
          f.save!
        else
          f.destroy
          destroyed += 1
        end
      end
      after_count = Forecast.where(temp_min: temp).count
      puts "Destroyed #{result} Predictions"
      puts "Destroyed #{destroyed} Forecasts"
      puts "Updated #{updated} Forecasts"
      puts "#{after_count} Forecasts exist with temp_min: #{temp}"
      if dryrun
        puts "Rolling back - no changes persisted"
        raise ActiveRecord::Rollback
      end
    end
  end

  private
  def compute_stats
    min_temp = 99999
    max_temp = -9999
    time_temps = {}  # { time => temp}
    
    min_wind = 99999
    max_wind = -9999
    time_winds = {}  # { time => winds}
    predictions_for.each do |p|
      # scan for Temp min/max
      if p.temperature
        if p.temperature <= min_temp
          min_temp = p.temperature 
          time_temps[p.forecast.time] = p.temperature
        end
        if p.temperature >= max_temp
          max_temp = p.temperature
          time_temps[p.forecast.time] = p.temperature
        end
      end
      # scan for Wind min/max
      if p.wind_speed
        if p.wind_speed <= min_wind
          min_wind = p.wind_speed 
          time_winds[p.forecast.time] = p.wind_speed
        end
        if p.wind_speed >= max_wind
          max_wind = p.wind_speed
          time_winds[p.forecast.time] = p.wind_speed
        end
      end
    end

    # update temp stats
    self.temp_min = min_temp
    self.temp_max = max_temp
    self.temp_diff = (min_temp-max_temp).abs
    if self.temp_diff > 0
      min_times = time_temps.select{|time, temp| temp == min_temp}.keys
      max_times = time_temps.select{|time, temp| temp == max_temp}.keys
      self.temp_diff_hours = ((min_times.map{|min| max_times.map{|max| (min-max).abs}}.flatten.min)/3600).to_i
      self.temp_diff_per_hour = temp_diff/temp_diff_hours.to_f
    else
      self.temp_diff_hours = 0
      self.temp_diff_per_hour = 0
    end

    # update wind stats
    self.wind_min = min_wind
    self.wind_max = max_wind
    self.wind_diff = (min_wind-max_wind).abs
    if self.wind_diff > 0 
      min_times = time_winds.select{|time, wind| wind == min_wind}.keys
      max_times = time_winds.select{|time, wind| wind == max_wind}.keys
      self.wind_diff_hours = ((min_times.map{|min| max_times.map{|max| (min-max).abs}}.flatten.min)/3600).to_i
      self.wind_diff_per_hour = wind_diff/wind_diff_hours.to_f
    else
      self.wind_diff_hours = 0
      self.wind_diff_per_hour = 0
    end
    if self.respond_to?(:current_temp)
      self.current_temp = current_prediction&.temperature
      self.current_wind = current_prediction&.wind_speed
    end
    true
  end

end
