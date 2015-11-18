module LaunchControl

  require 'reform'
  require 'reform/form/active_model/validations'
  require 'active_support/concern'

  Reform::Form.class_eval do
    include Reform::Form::ActiveModel::Validations
  end

  class NullValidate
    def method_missing(action,*params,&block)
      true
    end
  end

  class BaseContract < Reform::Form

    include Reform::Form::ActiveModel

    #
    # As we want the benefits of Reform for testing
    # the validity of the params hash, but don't have
    # underlying objects that we're actually writing to,
    # we're supplying a NullValidate object to satisfy
    # Reform & automatically setting all properties to
    # virtual by default.
    #
    def self.property(name, options={}, &block)
      options = { virtual: true, writable: false }.merge(options)
      super
    end

    def initialize(options={})
      @fields = {}
      @model  = NullValidate.new
      @mapper = mapper_for(@model) # mapper for model.

      setup_properties!(options)
    end

  end

  class MandrillContract < BaseContract

    property  :to
    property  :subject
    validates :to, :subject, presence: true

    def template
      raise 'You must define a Mandrill template to use'
    end

    def deliver(options)
      launch = LaunchControl::Mailer.new(template, options)
      validate(options) && launch.valid? && launch.deliver
    end

  end

  #
  # Use this to explicity declare you have no reliant
  # merge variables.
  #
  # e.g.
  #
  #    NullContract.new('template-name')
  #
  # class NullContract

  #   attr_reader :template

  #   def initialize(template)
  #     @template = template
  #   end

  #   def validate?
  #     true
  #   end

  #   def deliver
  #     true
  #   end

  # end
end
