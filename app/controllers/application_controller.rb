class ApplicationController < ActionController::Base

  around_action :with_time_zone
  
  def with_time_zone(&block)
      Time.use_zone('MST', &block)
  end

end
