# Rack::SteadyETag

By default Rails generates [`ETag`](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/ETag) headers by hashing the response body. In theory this would [enable caching](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/If-None-Match) for multiple requests to the same resource. However, since layouts often insert randomly rotating CSRF tokens and CSP nonces into the HTML, two requests for the same content and user will never produce the same response. This means the default ETags from Rails will [never hit a cache](https://github.com/rails/rails/issues/29889).

`Rack::SteadyETag` is a drop-in replacement for `Rack::ETag` in Rails' default middleware stack. It also generates `Etag` by hashing response body, but ignores CSRF tokens and CSP nonces from Rails helpers.


## Installation

Add this line to your application's Gemfile:

```ruby
gem 'rack-steady_etag'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install rack-steady_etag

## Usage

TODO: Write usage instructions here

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/rack-steady-etag.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Credits

[Rack Core Team](https://github.com/rack/rack#label-Thanks) and [Rack contributors](https://github.com/rack/rack/graphs/contributors).

## Limitations

No streaming support.

[This will be broken until at least Rack 3](https://github.com/rack/rack/issues/1619).
