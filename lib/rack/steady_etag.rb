# Based on Rack::Etag
# https://github.com/rack/rack/blob/master/lib/rack/etag.rb

require 'rack'
require_relative "steady_etag/version"
require 'digest/sha2'

module Rack

  # Automatically sets the ETag header on all String bodies.
  #
  # The ETag header is skipped if ETag or Last-Modified headers are sent or if
  # a sendfile body (body.responds_to :to_path) is given (since such cases
  # should be handled by apache/nginx).
  #
  # On initialization, you can pass two parameters: a Cache-Control directive
  # used when Etag is absent and a directive when it is present. The first
  # defaults to nil, while the second defaults to "max-age=0, private, must-revalidate"
  class SteadyETag
    ETAG_STRING = Rack::ETAG
    DEFAULT_CACHE_CONTROL = "max-age=0, private, must-revalidate"

    IGNORE_PATTERNS = [
      /<meta[^>]*\bname=(["']?)csrf-token\1[^>]+>/,
      /<input[^>]*\bname=(["']?)authenticity_token\1[^>]+>/,
    ]

    def initialize(app, no_digest_cache_control: nil, digest_cache_control: DEFAULT_CACHE_CONTROL)
      @app = app
      @digest_cache_control = digest_cache_control
      @no_digest_cache_control = no_digest_cache_control
    end

    def call(env)
      status, headers, body = @app.call(env)
      headers = Utils::HeaderHash[headers]

      if etag_status?(status) && body.respond_to?(:to_ary) && !skip_caching?(headers)
        body = body.to_ary
        digest = digest_body(body)
        headers[ETAG_STRING] = %(W/"#{digest}") if digest
      end

      unless headers[CACHE_CONTROL]
        if digest
          headers[CACHE_CONTROL] = @digest_cache_control if @digest_cache_control
        else
          headers[CACHE_CONTROL] = @no_digest_cache_control if @no_digest_cache_control
        end
      end

      [status, headers, body]
    end

    private

    def etag_status?(status)
      status == 200 || status == 201
    end

    def skip_caching?(headers)
      headers.key?(ETAG_STRING) || headers.key?('Last-Modified')
    end

    def digest_body(body)
      digest = nil

      body.each do |part|
        (digest ||= Digest::SHA256.new) << part unless part.empty?
      end

      digest && digest.hexdigest.byteslice(0,32)
    end
  end

end
