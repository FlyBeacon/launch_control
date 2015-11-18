module LaunchControl

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

    def merged_options(options)
      options
    end


    def deliver(options)
      options = merged_options(options)
      launch = LaunchControl::Mailer.new(template, options)
      valid?(options) && launch.valid? && launch.deliver
    end

    def default_email_contract
      {
        to:      lambda { |to| [Array,String,Hash].include?(to.class) },
        subject: 'string'
      }
    end

    def valid?(options)
      validator = HashValidator.validate(options, merged_contract)
      if validator.valid?
        true
      else
        @errors = validator.errors
        false
      end
    end

  end

end
