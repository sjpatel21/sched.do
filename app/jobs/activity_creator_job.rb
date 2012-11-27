class ActivityCreatorJob < Struct.new(:user_id, :action, :event_id)
  include Rails.application.routes.url_helpers

  PRIORITY = 1

  def self.enqueue(user, action, event)
    Delayed::Job.enqueue(
      new(user.id, action, event.id),
      priority: PRIORITY
    )
  end

  def perform
    configure_yammer
    Yam.post('/activity', json_payload)
  rescue Faraday::Error::ClientError
    Rails.logger.error("ActivityCreatorJob has failed. JSON was #{json_payload}")
    user.expire_token
  end

  def error(job, exception)
    Airbrake.notify(exception)
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

  def json_payload
    {
      activity: {
        actor: {
          name: user.name,
          email: user.email
        },
        action: action,
        object: {
          url: event_url(event),
          type: 'poll',
          title: event.name,
          image: 'http://' + ENV['HOSTNAME'] + '/logo.png'
        }
      },
      message: '',
      users: event.invitees_for_json
    }
  end

  def event
    Event.find(event_id)
  end
end
