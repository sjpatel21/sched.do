class ActivityCreatorJob < Struct.new(:user_id, :action, :event_id)
  PRIORITY = 1

  def self.enqueue(user, action, event)
    Delayed::Job.enqueue(
      new(user.id, action, event.id),
      priority: PRIORITY
    )
  end

  def perform
    configure_yammer
  end

  private

  def configure_yammer
    Yam.configure do |config|
      if user.yammer_user?
        config.oauth_token = user.access_token

        if user.yammer_staging
          config.endpoint = YAMMER_STAGING_ENDPOINT
        end
      end
    end
  end

  def user
    User.find(user_id)
  end
end
