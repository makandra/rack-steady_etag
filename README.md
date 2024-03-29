# Rack::SteadyETag


> **Important:**
> This gem has been deprecated. We instead recommend [reconfiguring your Rails app](https://makandracards.com/makandra/562483-rails-fixing-etags-that-never-match) so two requests to the same resource produce the same HTML for a given user.


`Rack::SteadyETag` is a Rack middleware that generates the same default [`ETag`](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/ETag) for responses that only differ in XOR-masked CSRF tokens or CSP nonces.

By default Rails uses [`Rack::ETag`](https://rdoc.info/github/rack/rack/Rack/ETag) to generate `ETag` headers by hashing the response body. In theory this would [enable caching](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/If-None-Match) for multiple requests to the same resource. However, since most Rails application layouts insert randomly rotating CSRF tokens and CSP nonces into the HTML, two requests for the same content and user will never produce the same response bytes. This means `Rack::ETag` will never send the same ETag twice, causing responses to [never hit a cache](https://github.com/rails/rails/issues/29889).

`Rack::SteadyETag` is a drop-in replacement for `Rack::ETag`. It excludes random content (like CSRF tokens) from the generated ETag, causing two requests for the same content to usually carry the same ETag.

## What is ignored

`Rack::SteadyTag`  ignores the following patterns from the `ETag` hash:

```html
<meta name="csrf-token" value="random" ...>
<meta name="csp-nonce" value="random" ...>
<input name="authenticity_token" value="random" ...>
<script nonce="random" ...> <!-- only the [nonce] attribute -->
```

You can add your own patterns:

```ruby
Rack::SteadyETag::STRIP_PATTERNS << /<meta name="XSRF-TOKEN" value="[^"]+">/
```

You can also push lambda for arbitrary transformations:

```ruby
Rack::SteadyETag::STRIP_PATTERNS << -> { |text| text.gsub(/<meta name="XSRF-TOKEN" value="[^"]+">/, '') }
```

Transformations are only applied for the `ETag` hash. The response body will not be changed.

## What responses are processed

This middleware will process responses that match all of the following: 

- Responses with a HTTP status of 200 or 201.
- Responses with a `Content-Type` of `text/html` or `application/xhtml+xml`.
- Responses with a body. 

Responses should also have an UTF-8 encoding (not checked by the middleware).

This middleware can also add a default `Cache-Control` header for responses it *didn't* process. This is passed as an argument during middleware initialization (see *Installation* below). 

## Covered edge cases

- Different `ETags` are generated when the same content is accessed with different Rack sessions.
- Different `ETags` are generated when a Rails controller manually rotates the CSRF token.
- `ETags` are only generated when the response is `Cache-Control: private` (this is a default in Rails).
- No `ETag` is generated when the response already has an `ETag` header.
- No `ETag` is generated when the response already has an `Last-Modified` header.


## Installation in Rails

Add this line to your application's Gemfile:

```ruby
gem 'rack-steady_etag'
```

And then execute:

```bash
bundle install
```

Make an initializer `config/initializer/etags.rb`:

```ruby
Rails.application.config.middleware.swap Rack::ETag, Rack::SteadyETag, 'no-cache'
```

The `'no-cache'` argument is the default `Cache-Control` for responses that cannot be digested. While it may feel surprising that the middleware changes the `Cache-Control` header in such a case, the [Rails default middleware stack](https://github.com/rails/rails/blob/d96609505511a76c618dc3adfa3ca4679317d008/railties/lib/rails/application/default_middleware_stack.rb#L81) configures the same behavior.


## Development

- After checking out the repo, run `bin/setup` to install dependencies.
- Run `bundle exec rspec` to run the tests.
- Run `BUNDLE_GEMFILE=Gemfile.rack1 bundle exec rspec` to run tests for old Rack 1.
- You can also run `bin/console` for an interactive prompt that will allow you to experiment.
- To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Credits

This library is based on `Rack::ETag`, created by the [Rack Core Team](https://github.com/rack/rack#label-Thanks) and [Rack contributors](https://github.com/rack/rack/graphs/contributors).

Additional changes by [Henning Koch](https://twitter.com/triskweline) from [makandra](https://makandra.com).

## Limitations

- No streaming support. [This will be broken until at least Rack 3](https://github.com/rack/rack/issues/1619). This is not a use case of mine.
