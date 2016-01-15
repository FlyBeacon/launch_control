module LaunchControl
  class ContractFailure < StandardError; end

  require 'hash_validator'

  class MandrillContract

    attr_accessor :errors

    #
    # Override this with any custom validations you wish
    # to perform on your mail object before delivering.
    #
    def validations
      {}
    end

    #
    # Override this with your template id from Mandrill.
    #
    def template
      raise 'You must define a Mandrill template to use'
    end

    #
    # Override these to control how your validations and
    # merge variables get integrated with Launch Control
    # defaults. For example:
    #
    #     def merged_options(options)
    #       options.merge(to_json)
    #     end
    #
    # This allows you to wrap any custom merge vars into
    # a to_json method for a cleaner interaction.
    #
    def merged_contract
      default_email_contract.merge!(validations)
    end

    def defaults
      {}
    end

    def merged_options(options)
      defaults.merge(options)
    end

    def deliver!(options = {})
      launch = LaunchControl::Mailer.new(template, merged_options(options))
      raise ContractFailure.new(error_string) unless valid?(options) && launch.valid?
      launch.deliver
    end

    def deliver(options)
      ActiveSupport::Deprecation.warn('deliver is deprecated. Use deliver! instead.')
      deliver!(options)
    end

    def default_email_contract
      # Note that subject is not required as it can be set in Mandrill
      {
        to: lambda { |to| [Array,String,Hash].include?(to.class) && to.present? }
      }
    end

    def valid?(options = {})
      merged_options = merged_options(options)
      validator = HashValidator.validate(merged_options, merged_contract)
      if validator.valid?
        true
      else
        @errors = validator.errors
        false
      end
    end

    def error_string
      (@errors || {}).map { |(attr, message)|
        "#{attr} #{message}"
      }.join(', ')
    end

    def string_present?
      lambda { |value| value.class == String && value.present? }
    end
  end
end
