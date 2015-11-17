# LaunchControl

LaunchControl eases and helps improve the integrity of mail delivered via Mandrill templates.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'launch_control'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install launch_control

Within your application (for a Rails app, typically /config/initializers/launch_control.rb), setup your Mandrill API key you wish to use:

    LaunchControl.configure do |config|
      config.mandrill_api_key = 'your_key_here'
    end

## Usage

    LaunchControl::Mailer.new('mandrill-template-id',
      to:        @booking.email,
      from:     'no-reply@test.com',
      subject:  'Hi Mum!',
      template_variable_one: 'Howdy!',
      template_collection: [
        { one: 'two'   },
        { two: 'three' }
      ]
    ).deliver

    # TODO: Contract validation to come soon.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/launch_control.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

