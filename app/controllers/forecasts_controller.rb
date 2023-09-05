class ForecastsController < ApplicationController
  before_action :set_forecast, only: [:show]

  def show

  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_forecast
      @forecast = Forecast.find(params[:id])
    end

end