module LaunchControl

  require 'hash_validator'

  class MandrillContract

    attr_accessor :errors

    def basic_email_contract
      {
        to:      lambda { |to| [Array,String,Hash].include?(to.class) },
        subject: 'string'
      }
    end

    def validations
      {}
    end

    def template
      raise 'You must define a Mandrill template to use'
    end

    def deliver(options)
      launch = LaunchControl::Mailer.new(template, options)
      valid?(options) && launch.valid? && launch.deliver
    end

    def valid?(options)
      contract = basic_email_contract.merge(validations)
      validator = HashValidator.validate(options, contract)
      if validator.valid?
        true
      else
        @errors = validator.errors
        false
      end
    end

  end

end
