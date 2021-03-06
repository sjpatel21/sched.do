require 'spec_helper'

describe InvitationsController, 'authentication' do
  it 'requires guest or yammer login for #create' do
    post :create

    should redirect_to new_guest_url
  end
end

describe InvitationsController, '.create' do
  context 'signed in as a user' do
    it 'redirects to the event page' do
      event_creator = create_user_and_sign_in
      event = create_event_and_mock_find(event_creator)

      post :create,
        invitation: {
          invitee_attributes: { name_or_email: 'invitee@example.com' },
          event_id: event.id
        }

      should redirect_to event_url(event.uuid)
    end

    it 'displays flash errors if the invitation does not save' do
      event_creator = create_user_and_sign_in
      event = create_event_and_mock_find(event_creator)

      post :create,
        invitation: {
          invitee_attributes: { name_or_email: 'invalid input' },
          event_id: event.id
        }

      flash[:error].should == 'Invitee is invalid'
    end

    it 'creates the appropriate invitation' do
      event_creator = create_user_and_sign_in
      event = create_event_and_mock_find(event_creator)
      invitee = create(:user)

      post :create,
        invitation: {
          invitee_attributes: { name_or_email: invitee.email },
          event_id: event.id
        }

      invitation = Invitation.find_by_invitee_id(invitee)

      invitation.event_id.should == event.id
      invitation.invitee_id.should == invitee.id
      invitation.invitee_type.should == invitee.class.name
      invitation.sender_id.should == event_creator.id
      invitation.sender_type.should == event_creator.class.name
    end

    it 'creates multiple invitations when multiple guests are invited' do
      event_creator = create_user_and_sign_in
      event = create_event_and_mock_find(event_creator)
      emails = 'guest1@example.com, guest2@example.com'

      post :create,
        invitation: {
          invitee_attributes: { name_or_email: emails },
          event_id: event.id
        }

      Invitation.count.should == 2
    end

    it 'creates multiple invitations for the correct users' do
      event_creator = create_user_and_sign_in
      event = create_event_and_mock_find(event_creator)
      Invitation.stubs(:new).returns(mock('invitation') { expects(:save).returns(true).twice })

      emails = 'guest1@example.com, guest2@example.com'
      InviteeBuilder.expects(:new).with('guest1@example.com', event).returns(stub_everything).once
      InviteeBuilder.expects(:new).with('guest2@example.com', event).returns(stub_everything).once

      post :create,
        invitation: {
          invitee_attributes: { name_or_email: emails },
          event_id: event.id
      }
    end

    def create_user_and_sign_in
      user = create(:user)
      sign_in_as(user)
      user
    end

    def create_event_and_mock_find(user)
      event = build_stubbed(:event, owner: user)
      Event.expects(:find).with(event.id.to_s).returns(event)
      event
    end
  end
end
