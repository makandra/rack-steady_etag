# Based on tests for Rack::Etag
# https://github.com/rack/rack/blob/master/test/spec_etag.rb
describe Rack::SteadyEtag do

  def etag(app, *args, **kwargs)
    Rack::Lint.new Rack::SteadyETag.new(app, *args, **kwargs)
  end

  def request
    Rack::MockRequest.env_for
  end

  def sendfile_body
    File.new(File::NULL)
  end

  def html_response(html, headers = {})
    app = lambda { |env| [200, headers.reverse_merge('Content-Type' => 'text/html'), [html]] }
    etag(app).call(request)
  end

  matcher :have_same_etag_as do |response2|
    match do |response1|
      etag1 = response1[1]['ETag']
      etag2 = response2[1]['ETag']

      etag1.present? && etag2.present? && etag1 == etag2
    end

    failure_message do |response1|
      "expected '#{etag(response1)}' to be the same ETag as #{etag(response2)}"
    end

    failure_message_when_negated do |response1|
      "expected responses to have different ETags, but both had #{etag(response1)}"
    end

    def etag(response)
      response[1]['ETag']
    end
  end

  it 'generates the same ETag for two equal response bodies' do
    response1 = html_response('Foo')
    response2 = html_response('Foo')

    expect(response1).to have_same_etag_as(response2)
  end

  it 'generates different ETags for different response bodies' do
    response1 = html_response('Foo')
    response2 = html_response('Bar')

    expect(response1).not_to have_same_etag_as(response2)
  end

  it "generates the same ETags for two bodies that only differ in head's CSRF token" do
    response1 = html_response(<<~HTML)
      <head>
        <meta name="csrf-token" content="6EueAlhls9P" />
      </head>
    HTML

    response2 = html_response(<<~HTML)
      <head>
        <meta name="csrf-token" content="qMN0fkVqOg" />
      </head>
    HTML

    expect(response1).to have_same_etag_as(response2)
  end

  it "generates the same ETags for two bodies that only differ in form's authenticity token token" do
    response1 = html_response(<<~HTML)
      <form>
        <input type="hidden" name="authenticity_token" content="123" />
      </form>
    HTML

    response2 = html_response(<<~HTML)
      <form>
        <input type="hidden" name="authenticity_token" content="456" />
      </form>
    HTML

    expect(response1).to have_same_etag_as(response2)
  end

  it "does not ignore patterns for digest when Cache-Control isn't private" do
    response1 = html_response(<<~HTML, { 'Cache-Control' => 'public' })
      <head>
        <meta name="csrf-token" content="6EueAlhls9P" />
      </head>
    HTML

    response2 = html_response(<<~HTML)
      <head>
        <meta name="csrf-token" content="qMN0fkVqOg" />
      </head>
    HTML

    expect(response1).to_not have_same_etag_as(response2)
  end

  it 'generates weak ETags because we only digest the response body' do
    response = html_response('Foo')
    expect(response[1]['ETag']).to start_with("W/")
  end

  # Tests from Rack::Test

  it "set ETag if none is set if status is 200" do
    app = lambda { |env| [200, { 'Content-Type' => 'text/plain' }, ["Hello, World!"]] }
    response = etag(app).call(request)
    expect(response[1]['ETag']).to eq "W/\"dffd6021bb2bd5b0af676290809ec3a5\""
  end

  it "set ETag if none is set if status is 201" do
    app = lambda { |env| [201, { 'Content-Type' => 'text/plain' }, ["Hello, World!"]] }
    response = etag(app).call(request)
    expect(response[1]['ETag']).to eq "W/\"dffd6021bb2bd5b0af676290809ec3a5\""
  end

  it "set Cache-Control to 'max-age=0, private, must-revalidate' (default) if none is set" do
    app = lambda { |env| [201, { 'Content-Type' => 'text/plain' }, ["Hello, World!"]] }
    response = etag(app).call(request)
    expect(response[1]['Cache-Control']).to eq 'max-age=0, private, must-revalidate'
  end

  it "set Cache-Control to chosen one if none is set" do
    app = lambda { |env| [201, { 'Content-Type' => 'text/plain' }, ["Hello, World!"]] }
    response = etag(app, digest_cache_control: 'public').call(request)
    expect(response[1]['Cache-Control']).to eq 'public'
  end

  it "set a given Cache-Control even if digest could not be calculated" do
    app = lambda { |env| [200, { 'Content-Type' => 'text/plain' }, []] }
    response = etag(app, no_digest_cache_control: 'no-cache').call(request)
    expect(response[1]['Cache-Control']).to eq 'no-cache'
  end

  it "not set Cache-Control if it is already set" do
    app = lambda { |env| [201, { 'Content-Type' => 'text/plain', 'Cache-Control' => 'public' }, ["Hello, World!"]] }
    response = etag(app).call(request)
    expect(response[1]['Cache-Control']).to eq 'public'
  end

  it "not set Cache-Control if directive isn't present" do
    app = lambda { |env| [200, { 'Content-Type' => 'text/plain' }, ["Hello, World!"]] }
    response = etag(app, no_digest_cache_control: nil, digest_cache_control: nil).call(request)
    expect(response[1]['Cache-Control']).to be_nil
  end

  it "not change ETag if it is already set" do
    app = lambda { |env| [200, { 'Content-Type' => 'text/plain', 'ETag' => '"abc"' }, ["Hello, World!"]] }
    response = etag(app).call(request)
    expect(response[1]['ETag']).to eq "\"abc\""
  end

  it "not set ETag if body is empty" do
    app = lambda { |env| [200, { 'Content-Type' => 'text/plain', 'Last-Modified' => Time.now.httpdate }, []] }
    response = etag(app).call(request)
    expect(response[1]['ETag']).to be_nil
  end

  it "not set ETag if Last-Modified is set" do
    app = lambda { |env| [200, { 'Content-Type' => 'text/plain', 'Last-Modified' => Time.now.httpdate }, ["Hello, World!"]] }
    response = etag(app).call(request)
    expect(response[1]['ETag']).to be_nil
  end

  it "not set ETag if a sendfile_body is given" do
    app = lambda { |env| [200, { 'Content-Type' => 'text/plain' }, sendfile_body] }
    response = etag(app).call(request)
    expect(response[1]['ETag']).to be_nil
  end

  it "not set ETag if a status is not 200 or 201" do
    app = lambda { |env| [401, { 'Content-Type' => 'text/plain' }, ['Access denied.']] }
    response = etag(app).call(request)
    expect(response[1]['ETag']).to be_nil
  end

  it "set ETag even if no-cache is given" do
    app = lambda { |env| [200, { 'Content-Type' => 'text/plain', 'Cache-Control' => 'no-cache, must-revalidate' }, ['Hello, World!']] }
    response = etag(app).call(request)
    expect(response[1]['ETag']).to eq "W/\"dffd6021bb2bd5b0af676290809ec3a5\""
  end

  it "close the original body" do
    body = StringIO.new
    app = lambda { |env| [200, {}, body] }
    response = etag(app).call(request)
    expect(body).to_not be_closed
    response[2].close
    expect(body).to be_closed
  end
end
