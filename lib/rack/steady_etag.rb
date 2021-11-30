require 'rack'
require 'digest/sha2'
require "active_support/all"
require_relative "steady_etag"
require_relative "steady_etag/version"

module Rack

  # Based on Rack::Etag
  # https://github.com/rack/rack/blob/master/lib/rack/etag.rb
  #
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
    DEFAULT_CACHE_CONTROL = "max-age=0, private, must-revalidate"

    IGNORE_PATTERNS = [
      /<meta[^>]*\bname=(["']?)csrf-token\1[^>]+>/,
      /<input[^>]*\bname=(["']?)authenticity_token\1[^>]+>/,
    ]

    def initialize(app, no_digest_cache_control: nil, digest_cache_control: DEFAULT_CACHE_CONTROL, ignore_patterns: IGNORE_PATTERNS.dup)
      @app = app
      @digest_cache_control = digest_cache_control
      @no_digest_cache_control = no_digest_cache_control
      @ignore_patterns = ignore_patterns
    end

    def call(env)
      status, headers, body = @app.call(env)
      headers = Utils::HeaderHash[headers]

      if etag_status?(status) && body.respond_to?(:to_ary) && !skip_caching?(headers)
        body = body.to_ary
        digest = digest_body(headers, body)
        headers[ETAG] = %(W/"#{digest}") if digest
      end

      [status, headers, body]
    end

    private

    def set_cache_control_with_digest(headers)
      headers[CACHE_CONTROL] ||= @digest_cache_control if @digest_cache_control
    end

    def set_cache_control_without_digest(headers)
      headers[CACHE_CONTROL] ||= @no_digest_cache_control if @no_digest_cache_control
    end

    def etag_status?(status)
      status == 200 || status == 201
    end

    def skip_caching?(headers)
      headers.key?(ETAG) || headers.key?('Last-Modified')
    end

    def cache_control_private?(headers)
      headers[CACHE_CONTROL] && headers[CACHE_CONTROL] =~ /\bprivate\b/
    end

    def digest_body(headers, body)
      digest = nil

      body.each do |part|
        if part.present?
          set_cache_control_with_digest(headers)

          if cache_control_private?(headers)
            @ignore_patterns.each do |ignore_pattern|
              part = part.gsub(ignore_pattern, '')
            end
          end

          digest ||= Digest::SHA256.new
          digest << part
        end
      end

      if digest
        digest.hexdigest.byteslice(0,32)
      else
        set_cache_control_without_digest(headers)
      end
    end
  end

end
