require 'spec_helper'

describe ActivityCreator, '#post' do
  include DelayedJobSpecHelper

  it 'posts to the Yammer API on post' do
    Yam.stubs(:post)
    user = build_user
    action = 'vote'
    event = build_stubbed(:event_with_invitees)

    ActivityCreator.new(user: user, action: action, event: event).post
    work_off_delayed_jobs

    Yam.should have_received(:post).with(
      '/activity',
      expected_json(event)
   )
  end

  it 'expires the access_token if it is stale' do
    user = build_user('OLDTOKEN')
    Yam.oauth_token = user.access_token
    action = 'vote'
    event = build_stubbed(:event_with_invitees)

    ActivityCreator.new(user: user, action: action, event: event).post

    user.access_token.should == 'EXPIRED'
    Yam.set_defaults
  end

  it 'logs an error if the access token is stale' do
    fake_logger = stub(error: 'blah')
    Rails.stubs(logger: fake_logger)
    user = build_user('OLDTOKEN')
    Yam.oauth_token = user.access_token
    action = 'vote'
    event = build_stubbed(:event_with_invitees)

    ActivityCreator.new(user, action, event).post

    fake_logger.should have_received(:error)
  end

  private

  def build_user(token = 'ABC123')
    user = create(
      :user,
      email: 'fred@example.com',
      access_token: token,
      name: 'Fred Jones'
    )
  end

  def expected_json(event)
    {
      activity: {
        actor: {
          name: 'Fred Jones',
          email: 'fred@example.com'
        },
        action: 'vote',
        object: {
          url: Rails.application.routes.url_helpers.event_url(event),
          type: 'poll',
          title: event.name,
          image: 'http://' + ENV['HOSTNAME'] + '/logo.png'
        }
      },
      message: '',
      users: event.invitees_for_json
    }
  end
end
