require 'digest/sha2'
require "active_support/all"
require_relative "steady_etag"
require_relative "steady_etag/version"

module Rack

  # Based on Rack::Etag from rack 2.2.3
  # https://github.com/rack/rack/blob/v2.2.3/lib/rack/etag.rb
  #
  # Automatically sets the ETag header on all String bodies.
  #
  # The ETag header is skipped if ETag or Last-Modified headers are sent or if
  # a sendfile body (body.responds_to :to_path) is given (since such cases
  # should be handled by apache/nginx).
  class SteadyETag

    # Yes, Rack::ETag sets a default Cache-Control for responses that it can digest.
    DEFAULT_CACHE_CONTROL = "max-age=0, private, must-revalidate"

    STRIP_PATTERNS = [
      /<meta\b[^>]*\bname=(["'])csrf-token\1[^>]+>/i,
      /<meta\b[^>]*\bname=(["'])csp-nonce\1[^>]+>/i,
      /<input\b[^>]*\bname=(["'])authenticity_token\1[^>]+>/i,
      lambda { |string| string.gsub(/(<script\b[^>]*)\bnonce=(["'])[^"']+\2+/i, '\1') }
    ]

    STRIP_CONTENT_TYPES = %w[
      text/html
      application/xhtml+xml
    ]

    def initialize(app, no_digest_cache_control = nil, digest_cache_control = DEFAULT_CACHE_CONTROL)
      @app = app

      @digest_cache_control = digest_cache_control

      # Rails sets a default `Cache-Control: no-cache` for responses that we cannot digest.
      # See https://github.com/rails/rails/blob/d96609505511a76c618dc3adfa3ca4679317d008/railties/lib/rails/application/default_middleware_stack.rb#L81
      @no_digest_cache_control = no_digest_cache_control
    end

    def call(env)
      status, headers, body = @app.call(env)
      headers = Utils::HeaderHash[headers]
      session = env[RACK_SESSION]

      if etag_status?(status) && etag_body?(body) && !skip_caching?(headers)
        original_body = body
        digest, new_body = digest_body(body, headers, session)
        body = Rack::BodyProxy.new(new_body) do
          original_body.close if original_body.respond_to?(:close)
        end
        headers[ETAG] = %(W/"#{digest}") if digest
      end

      # It would make more sense to only set a Cache-Control for responses that we process.
      # However, the original Rack::ETag sets Cache-Control: @no_digest_cache_control
      # for all responses, even responses that we don't otherwise modify.
      # Hence if we move this code into the `if` above we would remove Rails' default
      # Cache-Control headers for non-digestable responses, which would be a considerable
      # change in behavior.
      if digest
        set_cache_control_with_digest(headers)
      else
        set_cache_control_without_digest(headers)
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

    def etag_body?(body)
      # Rack main branch checks for `:to_ary` here to exclude streaming responses,
      # but that had other issues for me in testing. Maybe recheck when there is a
      # new Rack release after 2.2.3.
      !body.respond_to?(:to_path)
    end

    def skip_caching?(headers)
      headers.key?(ETAG) || headers.key?('Last-Modified')
    end

    def digest_body(body, headers, session)
      parts = []
      digest = nil

      strippable_response = STRIP_CONTENT_TYPES.include?(headers['Content-Type'])

      body.each do |part|
        parts << part

        # Note that `part` can be a string with binary data here.
        # It's important to check emptiness with #empty? instead of #blank?, since #blank?
        # internally calls String#match? and that explodes if the string is not valid UTF-8.
        unless part.empty?
          digest ||= initialize_digest(session)
          part = strip_patterns(part) if strippable_response
          digest << part
        end
      end

      if digest
        digest = digest.hexdigest.byteslice(0,32)
      end

      [digest, parts]
    end

    def initialize_digest(session)
      digest = Digest::SHA256.new

      if session && (session_id = session['session_id'])
        digest << session_id.to_s
      end

      digest
    end

    def strip_patterns(html)
      STRIP_PATTERNS.each do |pattern|
        if pattern.respond_to?(:call)
          html = pattern.call(html)
        else
          html = html.gsub(pattern, '')
        end
      end
      html
    end

  end
end
