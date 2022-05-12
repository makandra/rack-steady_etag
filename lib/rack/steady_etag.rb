require 'byebug'
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
  class SteadyETag
    DEFAULT_CACHE_CONTROL = "max-age=0, private, must-revalidate"

    IGNORE_PATTERNS = [
      /<meta\b[^>]*\bname=(["'])csrf-token\1[^>]+>/i,
      /<meta\b[^>]*\bname=(["'])csp-nonce\1[^>]+>/i,
      /<input\b[^>]*\bname=(["'])authenticity_token\1[^>]+>/i,
      lambda { |string| string.gsub(/(<script\b[^>]*)\bnonce=(["'])[^"']+\2+/i, '\1') }
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
      session = env[RACK_SESSION]

      if etag_status?(status) && etag_body?(body) && !skip_caching?(headers)
        original_body = body
        digest, new_body = digest_body(body, headers, session)
        body = Rack::BodyProxy.new(new_body) do
          original_body.close if original_body.respond_to?(:close)
        end
        headers[ETAG] = %(W/"#{digest}") if digest
      end

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
      !body.respond_to?(:to_path)
    end

    def skip_caching?(headers)
      headers.key?(ETAG) || headers.key?('Last-Modified')
    end

    def digest_body(body, headers, session)
      parts = []
      digest = nil

      body.each do |part|
        parts << part

        if part.present?
          part = strip_ignore_patterns(part)

          unless digest
            digest = Digest::SHA256.new

            if session && (session_id = session['session_id'])
              digest << session_id.to_s
            end
          end

          digest << part
        end
      end

      if digest
        digest = digest.hexdigest.byteslice(0,32)
      end

      [digest, parts]
    end

    def strip_ignore_patterns(html)
      @ignore_patterns.each do |ignore_pattern|
        if ignore_pattern.respond_to?(:call)
          html = ignore_pattern.call(html)
        else
          html = html.gsub(ignore_pattern, '')
        end
      end
      html
    end

  end
end
