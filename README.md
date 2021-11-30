# Rack::SteadyETag

With `Rack::SteadyETag` two Rails responses with the same content will produce the same `ETag`, even if the HTML differs in CSRF tokens or CSP nonces.

By default Rails generates [`ETag`](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/ETag) headers by hashing the response body. In theory this would [enable caching](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/If-None-Match) for multiple requests to the same resource. However, since layouts often insert randomly rotating CSRF tokens and CSP nonces into the HTML, two requests for the same content and user will never produce the same response. This means the default ETags from Rails will [never hit a cache](https://github.com/rails/rails/issues/29889).

`Rack::SteadyETag` is a drop-in replacement for `Rack::ETag` in Rails' default middleware stack. It also generates `Etag` by hashing response body, but ignores CSRF tokens and CSP nonces from Rails helpers.


## What is ignored

The following patterns are ignored for the `ETag` digest:

```html
<meta name="csrf-token" value="random" ...>
<meta name="csp-nonce" value="random" ...>
<input name="authenticity_token" value="random" ...>
<script nonce="random" ...> <!-- only the [nonce] attribute -->
```

You can add your own patterns:

```ruby
Rack::SteadyETag::IGNORED_PATTERNS << /<meta name="XSRF-TOKEN" value="[^"]+">/
```

You can also push lambda for arbitrary transformations:

```ruby
Rack::SteadyETag::IGNORED_PATTERNS << -> { |text| text.gsub(/<meta name="XSRF-TOKEN" value="[^"]+">/, '') }
```

## Covered edge cases

- `ETags` are only generated when the response is `Cache-Control: private` (this is a default in Rails).
- No `ETag` is generated when the response already has an `ETag` header.
- No `ETag` is generated when the response already has an `Last-Modified` header.
- Different `ETags` are generated when the same content is accessed with different Rails sessions.
- Different `ETags` are generated when the same content is accessed with and without a Rails session.


## Installation

Add this line to your application's Gemfile:

```ruby
gem 'rack-steady_etag'
```

And then execute:

```bash
bundle install
```

In your `config/application.rb`:

```ruby
config.middleware.swap Rack::ETag, Rack::SteadyETag
```


## Development

- After checking out the repo, run `bin/setup` to install dependencies.
- Run `bundle exec rspec` to run the tests.
- You can also run `bin/console` for an interactive prompt that will allow you to experiment.
- To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/makandra/rack-steady-etag.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Credits

[Rack Core Team](https://github.com/rack/rack#label-Thanks) and [Rack contributors](https://github.com/rack/rack/graphs/contributors).

## Limitations

- No streaming support. [This will be broken until at least Rack 3](https://github.com/rack/rack/issues/1619). This is not a use case of mine.
