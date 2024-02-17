# frozen_string_literal: true

require 'rails_helper'

describe 'shared/inboxes/_message.html.erb', db_clean: :after_each do
  let(:person) { FactoryBot.create(:person) }
  let(:message) do
    FactoryBot.create(
      :message,
      body: input_body,
      subject: input_subject,
      inbox: person.inbox
    )
  end

  before :each do
    render 'shared/inboxes/message.html.erb', message: message
  end

  let(:input_body) { "<img src=x onerror=alert('NHBR');> The message body" }
  let(:input_subject) do
    "<script>alert('NHBR');</script> The message subject <iframe src='https://www.google.com' title='A search Engine'></iframe>"
  end

  # Test for the sanitized value.
  # The sanitized content should not have script tags, iframe tags and JavaScript event attributes.
  it 'renders sanitized content' do
    expect(rendered).not_to include('onerror=')
    expect(rendered).not_to include('<script>')
    expect(rendered).not_to include('<iframe>')
  end
end
