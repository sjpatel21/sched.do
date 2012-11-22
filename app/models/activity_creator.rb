class ActivityCreator
  include Rails.application.routes.url_helpers

  def initialize(params)
    @user = params[:user]
    @action = params[:action]
    @event = params[:event]
  end

  def post
    Yam.post('/activity', json_payload)
  rescue Faraday::Error::ClientError
    @user.expire_token
  end

  def json_payload
    {
      activity: {
        actor: {
          name: @user.name,
          email: @user.email
        },
        action: @action,
        object: {
          url: event_url(@event),
          type: 'poll',
          title: @event.name,
          image: 'http://' + ENV['HOSTNAME'] + '/logo.png'
        }
      },
      message: '',
      users: @event.invitees_for_json
    }
  end
end
