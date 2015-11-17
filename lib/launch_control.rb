require "launch_control/version"
require "launch_control/mandrill_contract"
require 'mandrill'
require 'pry'

module LaunchControl

  #
  # Use as so:
  #
  #     LaunchControl::Mailer.new('template-id', to: 'xyz', subject: 'Test').deliver
  #
  # Define global merge vars to integrate with your Mandrill template:
  #
  #     LaunchControl::Mailer.new('template-id', to: 'xyz', subject: 'Test', var1: 'Display Me').deliver
  #
  class Mailer

    attr_accessor :template_id, :cc, :bcc, :to, :from_name, :from_email,
                  :reply_to, :subject, :merge_vars

    def initialize(template_id, options)

      raise 'Please configure your Mandrill API key before trying to deliver emails.' if LaunchControl.configuration.mandrill_api_key.nil?

      @template_id = template_id
      @to          = options.delete(:to)
      @cc          = options.delete(:cc)
      @bcc         = options.delete(:bcc)
      @from_name   = options.delete(:from_name)
      @from_email  = options.delete(:from_email)
      @reply_to    = options.delete(:reply_to)
      @subject     = options.delete(:subject)
      @merge_vars  = options
    end

    def mandrill
      @mandrill ||= Mandrill::API.new(LaunchControl.configuration.mandrill_api_key)
    end

    def deliver
      if valid?
        mandrill.messages.send_template(@template_id, [], message, false)
      end
    end

    def valid?
      !!(@to && @subject && @template_id && validate_merge_vars_against_contract)
    end

    private

      def message
        {
          "headers" => {
            "Reply-To"        => @reply_to
          },
          "merge_language"    => "handlebars",
          "to"                => build_addresses,
          "subject"           => @subject,
          "from_name"         => @from_name,
          "from_email"        => @from_email,
          "global_merge_vars" => build_merge_vars
        }
      end

      def build_addresses
        [build_to, build_cc, build_bcc].reject(&:nil?).flatten
      end

      #
      # Defines build_to, build_cc & build_bcc methods.
      #
      # These can accept either singular or array collections
      # of Strings or Hashes.
      #
      # Some examples of possible to, cc & bcc values:
      #
      #     'test@test.com'
      #     { email: 'test@test.com', name: 'Test' }
      #     ['test@test.com', 'another@email.com']
      #
      [:to, :cc, :bcc].each do |i|
        define_method("build_#{i}") do |address=nil|
          current_address = address || instance_variable_get("@#{i}")
          case current_address
          when Array
            current_address.collect do |addr|
              send("build_#{i}".to_sym, addr)
            end.flatten
          when Hash
            [current_address.stringify_keys.merge({"type" => i.to_s })]
          when String
            [{ "email" => "#{current_address}", "type" => i.to_s }]
          end
        end
      end


      def build_merge_vars
        unless @merge_vars.empty?
          @merge_vars.collect { |key, value| { 'name' => key.to_s, 'content' => value } }
        else
          []
        end
      end

      #
      # TODO: Allow a contract to be defined
      #
      def validate_merge_vars_against_contract
        true
      end

  end


  #
  # Allow external configuration of Mandrill API Key &
  # potentially more in future.
  #
  # e.g.
  #
  #     LaunchControl.configure do |config|
  #       config.mandrill_api_key = 'your_key_here'
  #     end
  #
  # Reference: https://robots.thoughtbot.com/mygem-configure-block
  #
  class << self
    attr_accessor :configuration
  end

  def self.configure
    self.configuration ||= Configuration.new
    yield(configuration)
  end

  class Configuration
    attr_accessor :mandrill_api_key

    def initialize
      @mandrill_api_key = nil
    end
  end

end
