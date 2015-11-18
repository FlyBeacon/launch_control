require 'spec_helper'

describe LaunchControl do

  it 'has a version number' do
    expect(LaunchControl::VERSION).not_to be nil
  end

  before(:all) do
    LaunchControl.configure do |config|
      config.mandrill_api_key = 'fake'
    end
  end

  context 'successful mandrill interactions' do

    before(:each) do
      stub_request(:post, "https://mandrillapp.com/api/1.0/messages/send-template.json").
        to_return(status: 200, body: '[{ "email": "recipient.email@example.com",
                                         "status": "sent",
                                         "reject_reason": "hard-bounce",
                                         "_id": "abc123abc123abc123abc123abc123"
                                       }]', headers: {})
    end

    context 'given a simple mailer contract' do
      class SimpleContract < LaunchControl::MandrillContract
        def template
          'template-id'
        end
      end

      subject { SimpleContract.new }

      it 'should deliver when supplied correct parameters' do
        expect(subject.deliver(to: 'me@test.com', subject: 'Test', var: '123')).to be true
      end

      it 'should not deliver when parameters are invalid' do
        expect(subject.deliver(to: 'me@test.com', var: '123')).to be false
      end

    end

    context 'given a complex mailer contract' do

      class ComplexContract < LaunchControl::MandrillContract

        property  :yolo
        validates :yolo, presence: true

        def template
          'template-id'
        end
      end

      subject { ComplexContract.new }

      it 'should deliver when supplied correct parameters' do
        expect(subject.deliver(to: 'me@test.com', subject: 'Test', yolo: '123')).to be true
      end

      it 'should not deliver when parameters are invalid' do
        expect(subject.deliver(to: 'me@test.com', subject: 'Test', var: '123')).to be false
      end

    end

    context 'given a nested mailer contract' do

      class NestedContract < LaunchControl::MandrillContract

        collection :yolos, populator: lambda { |fragment, *args| LaunchControl::BaseContract.new } do
          property :one
          property :two
          validates :one, :two, presence: true
        end

        def template
          'template-id'
        end
      end

      subject { NestedContract.new }


      it 'should deliver when supplied correct parameters' do
        expect(subject.deliver(to: 'me@test.com', subject: 'Test', yolos: [{ one: '123', two: '321' }])).to be true
      end

      it 'should not deliver when parameters are invalid' do
        expect(subject.deliver(to: 'me@test.com', subject: 'Test', var: '123')).to be false
      end

    end

  end

end
