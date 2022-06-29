# TeslaHTTPCache

HTTP caching middleware for Tesla

⚠️ work in progress ⚠️

## Installation

```elixir
def deps do
  [
    {:tesla_http_cache, "~> 0.1.0"}
  ]
end
```

You need to setup a cache store as well for production use.
[http_cache_store_native](https://github.com/tanguilp/http_cache_store_native) is such a
store.

## Configuration

Options of this middleware are options of the [http_cache](https://hexdocs.pm/http_cache)
library, By default, the following options are set:
- `:type`: `:private`
- `:auto_accept_encoding`: `true`
- `:auto_compress`: `true`

The `:store` option must be set when configuring the middleware.

## Examples

Notice the `age` response header after the first request.

```elixir
iex> client = Tesla.client([{TeslaHTTPCache, store: :http_cache_store_process}])
%Tesla.Client{
  adapter: nil,
  fun: nil,
  post: [],
  pre: [{TeslaHTTPCache, :call, [[store: :http_cache_store_process]]}]
}

iex> Tesla.get!(client, "http://perdu.com")
%Tesla.Env{
  __client__: %Tesla.Client{
    adapter: nil,
    fun: nil,
    post: [],
    pre: [{TeslaHTTPCache, :call, [[store: :http_cache_store_process]]}]
  },
  __module__: Tesla,
  body: "<html><head><title>Vous Etes Perdu ?</title></head><body><h1>Perdu sur l'Internet ?</h1><h2>Pas de panique, on va vous aider</h2><strong><pre>    * <----- vous &ecirc;tes ici</pre></strong></body></html>\n",
  headers: [
    {"cache-control", "max-age=600"},
    {"date", "Wed, 29 Jun 2022 12:23:18 GMT"},
    {"accept-ranges", "bytes"},
    {"etag", "\"cc-5344555136fe9\""},
    {"server", "Apache"},
    {"vary", "Accept-Encoding,User-Agent"},
    {"content-type", "text/html"},
    {"expires", "Wed, 29 Jun 2022 12:33:18 GMT"},
    {"last-modified", "Thu, 02 Jun 2016 06:01:08 GMT"},
    {"content-length", "204"}
  ],
  method: :get,
  opts: [],
  query: [],
  status: 200,
  url: "http://perdu.com"
}

iex> Tesla.get!(client, "http://perdu.com")
%Tesla.Env{
  __client__: %Tesla.Client{
    adapter: nil,
    fun: nil,
    post: [],
    pre: [{TeslaHTTPCache, :call, [[store: :http_cache_store_process]]}]
  },
  __module__: Tesla,
  body: "<html><head><title>Vous Etes Perdu ?</title></head><body><h1>Perdu sur l'Internet ?</h1><h2>Pas de panique, on va vous aider</h2><strong><pre>    * <----- vous &ecirc;tes ici</pre></strong></body></html>\n",
  headers: [
    {"cache-control", "max-age=600"},
    {"date", "Wed, 29 Jun 2022 12:23:18 GMT"},
    {"accept-ranges", "bytes"},
    {"etag", "\"cc-5344555136fe9\""},
    {"server", "Apache"},
    {"vary", "Accept-Encoding,User-Agent"},
    {"content-type", "text/html"},
    {"expires", "Wed, 29 Jun 2022 12:33:18 GMT"},
    {"last-modified", "Thu, 02 Jun 2016 06:01:08 GMT"},
    {"content-length", "204"},
    {"age", "4"}
  ],
  method: :get,
  opts: [],
  query: [],
  status: 200,
  url: "http://perdu.com"
}

iex> Tesla.get!(client, "http://perdu.com", headers: [{"range", "bytes=12-43"}])
%Tesla.Env{
  __client__: %Tesla.Client{
    adapter: nil,
    fun: nil,
    post: [],
    pre: [{TeslaHTTPCache, :call, [[store: :http_cache_store_process]]}]
  },
  __module__: Tesla,
  body: "<title>Vous Etes Perdu ?</title>",
  headers: [
    {"cache-control", "max-age=600"},
    {"date", "Wed, 29 Jun 2022 12:23:18 GMT"},
    {"accept-ranges", "bytes"},
    {"etag", "\"cc-5344555136fe9\""},
    {"server", "Apache"},
    {"vary", "Accept-Encoding,User-Agent"},
    {"content-type", "text/html"},
    {"expires", "Wed, 29 Jun 2022 12:33:18 GMT"},
    {"last-modified", "Thu, 02 Jun 2016 06:01:08 GMT"},
    {"content-range", "bytes 12-43/204"},
    {"content-length", "32"},
    {"age", "125"}
  ],
  method: :get,
  opts: [],
  query: [],
  status: 206,
  url: "http://perdu.com"
}

iex> Tesla.get!(client, "http://perdu.com", headers: [{"cache-control", "no-cache"}])
%Tesla.Env{
  __client__: %Tesla.Client{
    adapter: nil,
    fun: nil,
    post: [],
    pre: [{TeslaHTTPCache, :call, [[store: :http_cache_store_process]]}]
  },
  __module__: Tesla,
  body: "<html><head><title>Vous Etes Perdu ?</title></head><body><h1>Perdu sur l'Internet ?</h1><h2>Pas de panique, on va vous aider</h2><strong><pre>    * <----- vous &ecirc;tes ici</pre></strong></body></html>\n",
  headers: [
    {"accept-ranges", "bytes"},
    {"content-type", "text/html"},
    {"last-modified", "Thu, 02 Jun 2016 06:01:08 GMT"},
    {"content-length", "204"},
    {"age", "1"},
    {"cache-control", "max-age=600"},
    {"connection", "Keep-Alive"},
    {"date", "Wed, 29 Jun 2022 12:28:10 GMT"},
    {"etag", "\"cc-5344555136fe9\""},
    {"server", "Apache"},
    {"vary", "User-Agent,Accept-Encoding"},
    {"expires", "Wed, 29 Jun 2022 12:38:10 GMT"},
    {"keep-alive", "timeout=5, max=98"}
  ],
  method: :get,
  opts: [],
  query: [],
  status: 200,
  url: "http://perdu.com"
}
```

## Telemetry events

The following events are emitted:
- `[:tesla_http_cache, :hit]` when a response is returned from the cache
  - measurements: none
  - metadata:
    - `:freshness`: one of
      - `:fresh`: a fresh response was returned
      - `:stale`: a stale response was returned
      - `:revalidated`: the response was successfully revalidated and returned
- `[:tesla_http_cache, :miss]` in case of cache miss
  - measurements: none
  - metadata: none
