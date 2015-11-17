module LaunchControl

  require 'reform'
  require "reform/form/active_model/validations"
  Reform::Form.class_eval do
    include Reform::Form::ActiveModel::Validations
  end

  class MandrillContract < Reform::Form

    include Reform::Form::ActiveModel

    property  :to
    validates :to, presence: true

    def template
      raise 'You must define a Mandrill template to use'
    end

  end

  class NullValidate
    def method_missing(action,*params,&block)
      puts action
      true
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
  class NullContract

    attr_reader :template

    def initialize(template)
      @template = template
    end

    def validate?
      true
    end

    def deliver
      true
    end

  end
end
