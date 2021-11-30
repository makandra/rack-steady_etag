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

  it 'generates different ETags for different response bodies'

  it 'generates the same ETag for different response bodies'

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
