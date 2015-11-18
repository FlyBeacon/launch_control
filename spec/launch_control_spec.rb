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

  class SimpleContract < LaunchControl::MandrillContract
    def template
      'template-id'
    end
  end

  class ComplexContract < LaunchControl::MandrillContract
    def validations
      {
        yolo: 'string'
      }
    end

    def template
      'template-id'
    end
  end

  #
  # TODO: testing the values of nested attributes is
  # still awkward. Not many validation libraries handle
  # this well - look to improve.
  #
  class NestedContract < LaunchControl::MandrillContract

    def validations
      {
        yolos: lambda { |i| i.all? { |j| j[:one].present? } }
      }
    end

    def template
      'template-id'
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

      subject { SimpleContract.new }

      it 'should deliver when supplied correct parameters' do
        expect(subject.deliver(to: 'me@test.com', subject: 'Test', var: '123')).to be true
      end

      it 'should not deliver when parameters are invalid' do
        expect(subject.deliver(to: 'me@test.com', var: '123')).to be false
      end

    end

    context 'given a complex mailer contract' do

      subject { ComplexContract.new }

      it 'should deliver when supplied correct parameters' do
        expect(subject.deliver(to: 'me@test.com', subject: 'Test', yolo: '123')).to be true
      end

      it 'should not deliver when parameters are invalid' do
        expect(subject.deliver(to: 'me@test.com', subject: 'Test', var: '123')).to be false
      end

    end


    context 'given a nested mailer contract' do

      subject { NestedContract.new }

      it 'should deliver when supplied correct parameters' do
        expect(subject.deliver(to: 'me@test.com', subject: 'Test', yolos: [{ one: '123'}])).to be true
      end

      let(:failing_hash) { { to: 'me@test.com', subject: 'Test', var: '123' } }

      it 'should not deliver when parameters are invalid' do
        expect(subject.deliver(failing_hash)).to be false
      end

      it 'should supply an error message' do
        subject.deliver(failing_hash)
        expect(subject.errors).to eq({ yolos: "is not valid" })
      end

    end

  end

  context 'failed mandrill interactions' do

    before(:each) do
      stub_request(:post, "https://mandrillapp.com/api/1.0/messages/send-template.json").
        to_return(status: 500, body: '', headers: {})
    end

    context 'given a simple mailer contract' do

      subject { SimpleContract.new }

      it 'should deliver when supplied correct parameters' do
        expect { subject.deliver(to: 'me@test.com', subject: 'Test') }.to raise_error
      end

    end
  end

end
