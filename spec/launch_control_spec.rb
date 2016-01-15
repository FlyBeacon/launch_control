require 'spec_helper'

RSpec.describe LaunchControl do

  it 'has a version number' do
    expect(LaunchControl::VERSION).not_to be nil
  end

  before(:all) do
    LaunchControl.configure do |config|
      config.mandrill_api_key = 'fake'
    end
  end

  class NoTemplateContract < LaunchControl::MandrillContract
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

    before do
      stub_request(:post, "https://mandrillapp.com/api/1.0/messages/send-template.json").
        to_return(status: 200, body: '[{ "email": "recipient.email@example.com",
                                         "status": "sent",
                                         "reject_reason": "none",
                                         "_id": "abc123abc123abc123abc123abc123"
                                       }]', headers: {})
    end

    context 'given a simple mailer contract' do

      subject { SimpleContract.new }

      it 'delivers when supplied correct parameters' do
        expect(subject.deliver!(to: 'me@test.com', subject: 'Test', var: '123')).to be true
      end

      it 'does not deliver when parameters are invalid' do
        expect { subject.deliver!(to: 'me@test.com', var: '123') }.to raise_error(LaunchControl::ContractFailure)
      end

    end

    context 'given a complex mailer contract' do

      subject { ComplexContract.new }

      it 'delivers when supplied correct parameters' do
        expect(subject.deliver!(to: 'me@test.com', subject: 'Test', yolo: '123')).to be true
      end

      it 'does not deliver when parameters are invalid' do
        expect { subject.deliver!(to: 'me@test.com', subject: 'Test', var: '123') }.to raise_error(LaunchControl::ContractFailure)
      end
    end


    context 'given a nested mailer contract' do

      subject { NestedContract.new }

      it 'delivers when supplied correct parameters' do
        expect(subject.deliver!(to: 'me@test.com', subject: 'Test', yolos: [{ one: '123'}])).to be true
      end

      let(:failing_hash) { { to: 'me@test.com', subject: 'Test', var: '123' } }

      it 'does not deliver when parameters are invalid' do
        expect { subject.deliver!(failing_hash) }.to raise_error(LaunchControl::ContractFailure)
      end

      it 'supplies an error message' do
        expect { subject.deliver!(failing_hash) }.to raise_error(LaunchControl::ContractFailure, 'yolos is not valid')
      end
    end

    context 'given a NoTemplateContract' do

      subject { NoTemplateContract.new }

      it 'does not deliver when parameters are invalid' do
        expect { subject.deliver!(to: 'test', subject: 'test') }.to raise_error(RuntimeError)
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

      it 'delivers when supplied correct parameters' do
        expect { subject.deliver!(to: 'me@test.com', subject: 'Test') }.to raise_error(Mandrill::Error)
      end
    end
  end

end
