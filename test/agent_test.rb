require File.expand_path("../helper", __FILE__)

module Sawyer
  class AgentTest < TestCase
    def setup
      @stubs = Faraday::Adapter::Test::Stubs.new
      @agent = Sawyer::Agent.new "http://foo.com/a/" do |conn|
        conn.builder.handlers.delete(Faraday::Adapter::NetHttp)
        conn.adapter :test, @stubs
      end
    end

    def test_starts_a_session
      @stubs.get '/a/' do |env|
        assert_equal 'foo.com', env[:url].host

        [200, {}, Yajl.dump(
          :_links => {
            :users => {:_href => '/users'}})]
      end

      res = @agent.start

      assert_equal 200, res.status
      assert_kind_of Sawyer::Resource, resource = res.data

      assert_equal '/users', resource.rels[:users].href
      assert_equal :get,     resource.rels[:users].method
    end

    def test_requests_with_body_and_options
      @stubs.post '/a/b/c' do |env|
        assert_equal '{"a":1}', env[:body]
        assert_equal 'abc',     env[:request_headers]['x-test']
        assert_equal 'foo=bar', env[:url].query
        [200, {}, "{}"]
      end

      res = @agent.call :post, 'b/c' , {:a => 1},
        :headers => {"X-Test" => "abc"},
        :query   => {:foo => 'bar'}
      assert_equal 200, res.status
    end

    def test_requests_with_body_and_options_to_get
      @stubs.get '/a/b/c' do |env|
        assert_nil env[:body]
        assert_equal 'abc',     env[:request_headers]['x-test']
        assert_equal 'foo=bar', env[:url].query
        [200, {}, "{}"]
      end

      res = @agent.call :get, 'b/c' , {:a => 1},
        :headers => {"X-Test" => "abc"},
        :query   => {:foo => 'bar'}
      assert_equal 200, res.status
    end
  end
end
