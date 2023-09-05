# https://betterprogramming.pub/devise-auth-setup-in-rails-7-44240aaed4be
# https://gorails.com/episodes/devise-hotwire-turbo
class TurboDeviseController < ApplicationController
  class Responder < ActionController::Responder
    def to_turbo_stream
      controller.render(options.merge(format: :html))
    rescue ActionView::MissingTemplate => error
      if get?
        raise error
      elsif has_errors? && default_action
        render rendering_options.merge(format: :html, status: :unprocessable_entity) # 422 error
      else
        redirect_to navigation_location
      end
    end
  end

  self.responder = Responder
  respond_to :html, :turbo_stream
end
