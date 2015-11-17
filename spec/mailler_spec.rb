module LaunchControl

  require 'spec_helper'

  describe Mailer do

    before(:all) do
      LaunchControl.configure do |config|
        config.mandrill_api_key = 'fake'
      end
    end

    context 'basic behavioural tests' do
      it 'sets a template id' do
        expect(Mailer.new('123', {}).template_id).to eq('123')
      end

      it 'extracts :to address from options' do
        expect(Mailer.new('123', { to: ['me@test.com'] }).to).to eq(['me@test.com'])
      end

      it 'extracts :from address from options' do
        expect(Mailer.new('123', { from_email: 'me@test.com' }).from_email).to eq('me@test.com')
      end

      it 'extracts :subject from options' do
        expect(Mailer.new('123', { subject: 'Flying on a Jet Plane' }).subject).to eq('Flying on a Jet Plane')
      end

      it 'is not valid without :to and :subject' do
        expect(Mailer.new('123', { from_email: ['me@test.com'] }).valid?).to be false
      end

      it 'is valid with correct parameters supplied' do
        expect(Mailer.new('123', { to: 'a', subject: 'b' }).valid?).to be true
      end
    end

    describe '#build_merge_vars' do

      subject { Mailer.new('123', test_var: 'Hello') }

      it 'correctly builds merge vars' do
        expect(subject.send(:build_merge_vars)).to eq [{ 'name' => 'test_var', 'content' => 'Hello' }]
      end
    end

    describe '#build_addresses' do
      context 'single :to address' do
        subject { Mailer.new('123', to: 'me@hello.com') }

        it 'creates correct email address structure for Mandrill' do
          expect(subject.send(:build_addresses)).to eq [{ 'email' => 'me@hello.com', 'type' => 'to' }]
        end
      end

      context 'multiple :to addresses' do
        subject { Mailer.new('123', to: ['me@hello.com', 'you@hello.com']) }

        it 'handles multiple :to addresses' do
          expect(subject.send(:build_addresses)).to eq [{"email"=>"me@hello.com", "type"=>"to"},
                                                        {"email"=>"you@hello.com", "type"=>"to"}]
        end
      end

      context 'muiltiple :cc and :bcc addresses' do
        subject { Mailer.new('123', cc: ['me@hello.com', 'you@hello.com'], bcc: 'test@test.com') }

        it 'handles :cc and :bcc addresses' do
          expect(subject.send(:build_addresses)).to eq [{"email"=>"me@hello.com", "type"=>"cc"},
                                                        {"email"=>"you@hello.com", "type"=>"cc"},
                                                        {"email"=>"test@test.com", "type"=>"bcc"}]
        end
      end

      context ':to address supplied as hash with name' do
        subject { Mailer.new('123', to: { email: 'me@hello.com', name: 'Tester' }) }

        it 'correctly maps email & name hashes' do
          expect(subject.send(:build_addresses)).to eq [{"email"=>"me@hello.com", "type"=>"to", "name" => "Tester"}]
        end
      end
    end

  end

end