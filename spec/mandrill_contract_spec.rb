require 'spec_helper'

module LaunchControl
  class TestContract < MandrillContract
    def template
      'test-template'
    end
  end

  class TestUserContract < MandrillContract
    def initialize(user)
      @user = user
    end

    def template
      'test-user-template'
    end

    def defaults
      { to: @user.email }
    end
  end

  RSpec.describe TestContract do

    subject { described_class.new }

    describe '#deliver!' do
      context 'with invalid options' do
        specify 'that an error is raised' do
          expect { subject.deliver! }.to raise_error(ContractFailure, 'to is not valid')
        end
      end

      context 'with valid options' do
        let(:options) do
          {
            to: 'dan@codehire.com',
            subject: 'Foo Test Subject'
          }
        end

        before do
          stub_request(:post, "https://mandrillapp.com/api/1.0/messages/send-template.json")
            .to_return(status: 200, body: '[{ "email": "recipient.email@example.com",
                                         "status": "sent",
                                         "reject_reason": "none",
                                         "_id": "abc123abc123abc123abc123abc123"
                                       }]', headers: {})

        end

        specify 'that the delivery is made' do
          expect { subject.deliver!(options) }.to_not raise_error
        end
      end
    end
  end

  RSpec.describe TestUserContract do

    subject { described_class.new(user) }

    describe '#deliver!' do
      context 'with invalid options' do
        let(:user) { double(:user, email: '') }

        specify 'that an error is raised' do
          expect { subject.deliver! }.to raise_error(ContractFailure, 'to is not valid')
        end
      end

      context 'with valid default options' do
        let(:user) { double(:user, email: 'dan@codehire.com') }

        context 'and no overides' do
          before do
            stub_request(:post, "https://mandrillapp.com/api/1.0/messages/send-template.json")
              .to_return(status: 200, body: '[{ "email": "recipient.email@example.com",
                                           "status": "sent",
                                           "reject_reason": "none",
                                           "_id": "abc123abc123abc123abc123abc123"
                                         }]', headers: {})
          end

          specify 'that the delivery is made' do
            expect { subject.deliver! }.to_not raise_error
          end
        end
        
        context 'and an invalid overide' do
          specify 'that an error is raised' do
            expect { subject.deliver!(to: '') }.to raise_error(ContractFailure, 'to is not valid')
          end
        end
      end
    end
  end
end
