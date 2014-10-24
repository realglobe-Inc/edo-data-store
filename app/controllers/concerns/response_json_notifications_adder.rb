module ResponseJsonNotificationsAdder
  extend ActiveSupport::Concern

  prepend Module.new{
    def render(**params)
      if params[:json] && notifications.present?
        params[:json][:notifications] = notifications
      end
      super
    end
  }

  private

  def notifications
    @notifications ||= []
  end
end
