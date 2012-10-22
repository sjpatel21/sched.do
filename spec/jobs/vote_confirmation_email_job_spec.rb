require 'spec_helper'

describe VoteConfirmationEmailJob, '.enqueue' do
  it 'enqueues the job' do
    vote = build_stubbed(:vote)

    VoteConfirmationEmailJob.enqueue(vote)

    should enqueue_delayed_job('VoteConfirmationEmailJob').
      with_attributes(vote_id: vote.id).
      priority(1).
      run_at(VoteConfirmationEmailJob::DELAY.from_now)
  end
end

describe VoteConfirmationEmailJob, '.error' do
  it 'sends Airbrake an exception if the job fails' do
    vote = build_stubbed(:vote)
    Airbrake.stubs(:notify)
    exception = 'Hey! you did something wrong!'

    job = VoteConfirmationEmailJob.new(vote.id)
    job.error(job, exception)

    Airbrake.should have_received(:notify).with(exception)
  end
end

describe VoteConfirmationEmailJob, '#perform' do
  include DelayedJobSpecHelper

  it 'does not send the email immediately' do
    mailer = stub('mailer', deliver: true)
    UserMailer.stubs vote_confirmation: mailer
    vote = build_stubbed(:vote)
    Vote.stubs find: vote

    VoteConfirmationEmailJob.enqueue(vote)
    work_off_delayed_jobs

    UserMailer.should have_received(:vote_confirmation).with(vote).never
  end

  it 'sends the email three minutes after the job is enqueued' do
    mailer = stub('mailer', deliver: true)
    UserMailer.stubs vote_confirmation: mailer
    vote = build_stubbed(:vote)
    Vote.stubs find: vote

    VoteConfirmationEmailJob.new(vote.id).perform

    Timecop.freeze(3.minutes.from_now) do
      UserMailer.should have_received(:vote_confirmation).with(vote)
    end
  end

  it 'sends only one email per user, every three minutes' do
    mailer = stub('mailer', deliver: true)
    UserMailer.stubs vote_confirmation: mailer

    first_vote = create(:vote)
    event = first_vote.suggestion.event
    second_suggestion = create(:suggestion, event: event)
    second_vote = create(:vote,
      voter: first_vote.voter,
      suggestion: second_suggestion)
    work_off_delayed_jobs
    Timecop.travel(3.minutes.from_now) do
      work_off_delayed_jobs
    end

    UserMailer.should have_received(:vote_confirmation).with(first_vote).never
    UserMailer.should have_received(:vote_confirmation).with(second_vote)
    mailer.should have_received(:deliver).once
  end
end
