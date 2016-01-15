require "launch_control/version"
require "launch_control/mandrill_contract"
require 'mandrill'
require 'active_support/core_ext/hash/keys'
require 'active_support/core_ext/object/blank'
require 'base64'

module LaunchControl

  #
  # To start using Launch Control, you first need to create a contract class, i.e.:
  #
  #     class ThankyouEmail < LaunchControl::MandrillContract
  #
  #       def template
  #         'thank-you'
  #       end
  #
  #       def validations
  #         {
  #           first_name: 'string',
  #           last_name:  'string'
  #         }
  #       end
  #     end
  #
  # Define global merge vars to integrate with your Mandrill template:
  #
  #     mailer = ThankyouEmail.new
  #     mailer.deliver(to: 'team@lotus.com', subject: 'Bring it home safely', first_name: 'Pastor', last_name: 'Maldonado')
  #      => true
  #
  # Now if you try and deliver this without the appropriate content, you'll be pulled up on it:
  #
  #     mailer.deliver(to: 'team@ferarri.com', subject: 'I know what I\'m doing', first_name: 'Kimi')
  #      => false
  #     mailer.errors
  #      => {:last_name=>"string required"}
  #
  #
  class Mailer

    attr_accessor :template_id, :cc, :bcc, :to, :from_name, :from_email,
                  :reply_to, :subject, :merge_vars, :status

    def initialize(template_id, options)
      options = options.dup

      raise 'Please configure your Mandrill API key before trying to deliver emails.' if LaunchControl.configuration.mandrill_api_key.nil?

      @template_id = template_id
      @to          = options.delete(:to)
      @cc          = options.delete(:cc)
      @bcc         = options.delete(:bcc)
      @from_name   = options.delete(:from_name)
      @from_email  = options.delete(:from_email)
      @reply_to    = options.delete(:reply_to)
      @subject     = options.delete(:subject)
      @attachments = options.delete(:attachments) || []
      @merge_vars  = options
    end

    def mandrill
      @mandrill ||= Mandrill::API.new(LaunchControl.configuration.mandrill_api_key)
    end

    def deliver
      if valid?
        response = mandrill.messages.send_template(@template_id, [], message, false)
        @status = response[0]["status"]
        ["sent", "queued", "scheduled"].include?(@status)
      end
    end

    def valid?
      !!(@to && @subject && @template_id)
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
          "global_merge_vars" => build_merge_vars,
          "attachments"       => build_attachments
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
        if @merge_vars.empty?
          []
        else
          @merge_vars.collect { |key, value| { 'name' => key.to_s, 'content' => value } }
        end
      end

      #
      # Expects an array of hashes containing the attachment details.
      #
      # i.e.
      #
      #     [{ type: 'text/plain', 'name': 'test.txt', content: '1234' }]
      #
      # Type is the mime type of the file.
      # Content is the content of the file, preferably in UTF-8 encoding.
      #
      def build_attachments
        if @attachments.empty?
          []
        else
          @attachments.collect do |attachment|
            next unless attachment.class == Hash
            {
              'type'    => attachment[:type],
              'name'    => attachment[:name],
              'content' => Base64.encode64(attachment[:content])
            }
          end
        end
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

  class Configuration
    attr_accessor :mandrill_api_key

    def initialize
      @mandrill_api_key = nil
    end
  end

  def self.configure
    self.configuration ||= Configuration.new
    yield(configuration) if block_given?
  end

  # Ensure default config
  configure
end
