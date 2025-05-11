defmodule TeslaHTTPCacheTest do
  use ExUnit.Case

  @http_cache_opts %{type: :private, store: :http_cache_store_process}
  @test_url "http://no-exist-domain-adsxikfgjs.com"
  @test_req {"GET", @test_url, [], ""}
  @test_resp {200, [], "Some content"}

  defmodule EchoAdapter do
    @behaviour Tesla.Adapter

    @impl true
    def call(env, _opts) do
      {:ok, env}
    end
  end

  defmodule UnreachableHostAdapter do
    @behaviour Tesla.Adapter

    @impl true
    def call(_env, _opts) do
      {:error, :econnrefused}
    end
  end

  defmodule OriginErrorAdapter do
    @behaviour Tesla.Adapter

    @impl true
    def call(env, http_status) do
      {:ok, %Tesla.Env{env | status: http_status}}
    end
  end

  setup do
    client =
      Tesla.client(
        [{TeslaHTTPCache, %{store: :http_cache_store_process}}],
        __MODULE__.EchoAdapter
      )

    {:ok, client: client}
  end

  test "returns cached response", %{client: client} do
    ref = :telemetry_test.attach_event_handlers(self(), [[:tesla_http_cache, :hit]])

    {:ok, _} = :http_cache.cache(@test_req, @test_resp, @http_cache_opts)

    {:ok, env} = Tesla.get(client, @test_url)

    assert env.status == 200
    assert env.body == "Some content"
    assert List.keymember?(env.headers, "age", 0)
    assert_received {[:tesla_http_cache, :hit], ^ref, _, %{freshness: :fresh, env: %Tesla.Env{}}}
  end

  test "handles query parameters", %{client: client} do
    {:ok, _} =
      :http_cache.cache(
        {"GET", Tesla.build_url(@test_url, param: "value"), [], ""},
        @test_resp,
        @http_cache_opts
      )

    {:ok, env} = Tesla.get(client, @test_url, query: [param: "value"])
    assert List.keymember?(env.headers, "age", 0)

    {:ok, env} = Tesla.get(client, @test_url, query: [param: "another-value"])
    refute List.keymember?(env.headers, "age", 0)
  end

  test "returns response stored in file", %{client: client} do
    :http_cache_store_process.save_in_file()
    {:ok, _} = :http_cache.cache(@test_req, @test_resp, @http_cache_opts)

    {:ok, env} = Tesla.get(client, @test_url)

    assert env.status == 200
    assert env.body == "Some content"
    assert List.keymember?(env.headers, "age", 0)
  end

  test "returns response stored in file with range", %{client: client} do
    :http_cache_store_process.save_in_file()
    {:ok, _} = :http_cache.cache(@test_req, @test_resp, @http_cache_opts)

    {:ok, env} = Tesla.get(client, @test_url, headers: [{"range", "bytes=0-3"}])

    assert env.status == 206
    assert env.body == "Some"
    assert List.keymember?(env.headers, "age", 0)
  end

  test "returns cached response when cache is disconnected and stale-if-error configured" do
    ref = :telemetry_test.attach_event_handlers(self(), [[:tesla_http_cache, :hit]])

    client =
      Tesla.client(
        [{TeslaHTTPCache, %{store: :http_cache_store_process}}],
        __MODULE__.UnreachableHostAdapter
      )

    {:ok, _} =
      :http_cache.cache(
        @test_req,
        {200, [{"cache-control", "max-age=0, stale-if-error=3600"}], "Some content"},
        @http_cache_opts
      )

    {:ok, env} = Tesla.get(client, @test_url)

    assert env.status == 200
    assert env.body == "Some content"
    assert List.keymember?(env.headers, "age", 0)
    assert_received {[:tesla_http_cache, :hit], ^ref, _, %{freshness: :stale, env: %Tesla.Env{}}}
  end

  for http_status <- [500, 502, 503, 504] do
    test "returns cached response when origin returns a #{http_status} error" do
      ref = :telemetry_test.attach_event_handlers(self(), [[:tesla_http_cache, :hit]])

      client =
        Tesla.client(
          [{TeslaHTTPCache, %{store: :http_cache_store_process}}],
          {__MODULE__.OriginErrorAdapter, unquote(http_status)}
        )

      {:ok, _} =
        :http_cache.cache(
          @test_req,
          {200, [{"cache-control", "max-age=0"}], "Some content"},
          @http_cache_opts
        )

      {:ok, env} =
        Tesla.get(client, @test_url, headers: [{"cache-control", "stale-if-error=3600"}])

      assert env.status == 200
      assert env.body == "Some content"
      assert List.keymember?(env.headers, "age", 0)

      assert_received {[:tesla_http_cache, :hit], ^ref, _,
                       %{freshness: :stale, env: %Tesla.Env{}}}
    end
  end

  test "raises when store option is missing" do
    client = Tesla.client([{TeslaHTTPCache, {}}])

    assert_raise RuntimeError, fn -> Tesla.get(client, @test_url) end
  end

  test "raises if body is not a binary or an IOlist", %{client: client} do
    assert_raise TeslaHTTPCache.InvalidBodyError, fn ->
      Tesla.get(client, @test_url, body: %{"some" => "json"})
    end
  end

  test "adds etag validator when validating response", %{client: client} do
    resp = {200, [{"etag", "some_etag"}, {"cache-control", "max-age=0"}], "Some content"}
    {:ok, _} = :http_cache.cache(@test_req, resp, @http_cache_opts)

    {:ok, env} = Tesla.get(client, @test_url)

    assert List.keymember?(env.headers, "if-none-match", 0)
  end

  test "adds last-modified validator when validating response", %{client: client} do
    resp =
      {200, [{"last-modified", "Wed, 21 Oct 2015 07:28:00 GMT"}, {"cache-control", "max-age=0"}],
       "Some content"}

    {:ok, _} = :http_cache.cache(@test_req, resp, @http_cache_opts)

    {:ok, env} = Tesla.get(client, @test_url)

    assert List.keymember?(env.headers, "if-modified-since", 0)
  end
end
