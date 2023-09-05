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

require 'json'
require 'rest-client'

class Station < ApplicationRecord
  include ::JsonService

  has_many :forecasts, dependent: :destroy
  has_many :predictions, dependent: :destroy
  belongs_to :current_forecast, class_name: "Forecast", foreign_key: "current_forecast_id", optional: true

  serialize :data, JSON

  # returns a hash of state abbreviations => largest temp_diff range for that state
  def self.build_state_range_diffs
    state_diffs = Hash.new(0)
    Station.find_each do |s|
      diff = s.current_forecast&.temp_diff
      state_diffs[s.state] = diff if diff && diff >= state_diffs[s.state]
    end
    state_diffs
  end

  # experimental - work in progress...
  # TODO: how to really represent 
  def self.build_state_errors(strategy = :variance)
    state_diffs = Hash.new(0)
    key = strategy == :variance ? :error_variance : :error_deviation
    Station.find_each do |s|
      f = s.current_forecast
      next if f.nil?
      error = f.current_statistics[key]
      state_diffs[s.state] = error if error && error >= state_diffs[s.state]
    end
    state_diffs
  end

  def self.build_state_days_diff(days_b4 = nil)
      state_diffs = Hash.new(0)
      Station.find_each do |s|
          f = s.current_forecast
          next if f.nil?
          preds = f.predictions_for
          temp_predicted = if days_b4.nil?
              preds[0].temperature
          else
              raise "todo"
              preds.detect{|p| p.created_at}
          end
          diff = f.current_temp - temp_predicted
          state_diffs[s.state] = diff if diff && diff.abs >= state_diffs[s.state].abs
      end
      state_diffs
  end

  def properties
    data['properties']
  end

  def time_zone
    properties['timeZone']
  end

  def start_and_end_utc_times_for_date(date)
    b4 = Time.zone
    Time.zone = self.time_zone
    if date.is_a?(String)
      date = Date.parse(date)
    end
    date = date.in_time_zone(Time.zone)
    dates = [date.beginning_of_day.utc, date.end_of_day.utc]
    puts "Start and end utc times for '#{date}'[#{Time.zone}] -- #{dates}"
    dates
  ensure
    Time.zone = b4
  end

  def day_summary(date)
    dates = start_and_end_utc_times_for_date(date)
    preds = self.predictions.where("start_time >= ? and start_time <= ?", *dates)
    grouped = preds.group_by{|p| p.start_time}
    Hash[grouped.map do |start_time, preds|
      [
        start_time.in_time_zone(self.time_zone).strftime("%I%P"), 
        Prediction.summarize_for_start_time(preds)
      ]
    end]
  end

  def current_temp
    current_forecast.current_prediction.temperature 
  rescue => e 
    "N/A"
  end

  def current_wind
    current_forecast.current_prediction.wind_speed
  rescue => e 
    "N/A"
  end



  # def __current_forecast
  #   forecasts.order("time DESC").first
  # end

  def compute_largest_diffs(top_n = 10)
    self.forecasts.order("temp_diff DESC").limit(10).map do |f|
      f.attributes.except('id', 'updated_at', 'created_at')
     end
  end

  def self.compute_largest_diffs
    largest_diffs = Station.find_each.map{|s| s.compute_largest_diffs(1)[0].merge({'station_id' => s.id, 
                                                                                'station_name' => s.name, 
                                                                                'station_state' => s.state })}
    largest_diffs.sort{|a,b| b['temp_diff'] <=> a['temp_diff']}
  end

  def self.retrieve_new_forecasts
    Station.find_each do |s| 
      begin
        if s.current_forecast.time > 1.hour.ago
          puts "Skipping Station[#{s.code}]"
          next
        end
        s.get_hourly_forecast
      rescue => e
        Rails.logger.error "Error retrieving new forecasts: #{e.message}"
        Rails.logger.error e.backtrace.join("\n")
      end
      sleep(5)
    end
  end

  def get_hourly_forecast
    Rails.logger.info "Station[#{code}].get_hourly_forecast"
    url = properties["forecastHourly"]
    data = json_service(url)   
    if data.nil?
      puts "No data returned - using current forecast"
      return current_forecast
    end
    _predictions = data['properties']['periods']
    # use the first startTime for recording all predictions
    forecast_time = Time.parse _predictions[0]['startTime']
    forecast = forecasts.where(time: forecast_time).first_or_create
    # Return if we've already processed these predictions
    if forecast.predictions.count > 0
      Rails.logger.info "  Forecast[#{forecast.id}] already had predictions for time: #{forecast_time}"
      return forecast
    end
    ActiveRecord::Base.transaction do
      _predictions.map do |p|
        start_time = Time.parse p['startTime']
        end_time = Time.parse p['endTime']
        temperature = p['temperature']
        temperature_unit = p['temperatureUnit']
        wind_speed, wind_unit = p['windSpeed'].split(" ") rescue [nil, nil]
        wind_direction = p['windDirection']
        short_forecast = p['shortForecast']
        if temperature.nil?
          raise "Invalid temperature encountered in prediction for Station[#{self.id}]" 
        end
        # icon eg: "https://api.weather.gov/icons/land/night/bkn?size=small"
        icon = p['icon'].split("/").last.split("?").first.gsub(",", "_") rescue nil

        forecast.predictions.create(station: self,
                                  start_time: start_time,
                                    end_time: end_time,
                                    temperature: temperature,
                                    temperature_unit: temperature_unit,
                                    wind_speed: wind_speed,
                                    wind_unit: wind_unit,
                                    wind_direction: wind_direction,
                                    short_forecast: short_forecast,
                                    icon: icon)
      end
      forecast.send(:compute_stats)
      forecast.end_time = forecast.predictions.last.start_time
      forecast.save!
      self.last_forecast_time = forecast_time
      self.current_forecast = forecast
      self.save!
    end # ActiveRecord::Base.transaction do
    return forecast
  end

  def self.create_from_lat_lon(lat, lon)
    station = Station.new
    url = "https://api.weather.gov/points/#{lat},#{lon}"
    data = station.json_service(url)
    station.data = data.as_json 
    station.code = data['properties']['cwa']
    station.name = data['properties']['relativeLocation']['properties']['city']
    station.city = data['properties']['relativeLocation']['properties']['city']
    station.state = data['properties']['relativeLocation']['properties']['state']
    station.save!
    return station
  end

end
