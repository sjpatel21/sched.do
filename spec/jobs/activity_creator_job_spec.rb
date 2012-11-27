require 'spec_helper'

describe ActivityCreatorJob, '.enqueue' do
  it 'enqueues the job' do
    user = build_stubbed(:user)
    action = 'vote'
    event = build_stubbed(:event)

    ActivityCreatorJob.enqueue(user, action, event)

    should enqueue_delayed_job('ActivityCreatorJob').
      with_attributes(user_id: user.id, action: action, event_id: event.id).
      priority(1)
  end
end

describe ActivityCreatorJob, '#perform' do
  it 'configures Yammer' do
    user = build_stubbed(:user)
    action = 'vote'
    event = build_stubbed(:event)
    User.stubs(find: user)

    ActivityCreatorJob.new(user, action, event).perform

    Yam.oauth_token.should == user.access_token
  end

  # it 'posts to the Yammer activity endpoint' do
  # end
end
