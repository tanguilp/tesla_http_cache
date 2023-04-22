# TeslaHTTPCache

HTTP caching middleware for Tesla

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
iex> client = Tesla.client([{TeslaHTTPCache, %{store: :http_cache_store_process}}])
%Tesla.Client{
  fun: nil,
  pre: [{TeslaHTTPCache, :call, [%{store: :http_cache_store_process}]}],
  post: [],
  adapter: nil
}
iex> Tesla.get!(client, "http://perdu.com")
%Tesla.Env{
  method: :get,
  url: "http://perdu.com",
  query: [],
  headers: [
    {"cache-control", "max-age=600"},
    {"date", "Sat, 22 Apr 2023 14:15:11 GMT"},
    {"etag", "W/\"cc-5344555136fe9-gzip\""},
    {"server", "cloudflare"},
    {"vary", "Accept-Encoding,User-Agent"},
    {"content-type", "text/html"},
    {"expires", "Sat, 22 Apr 2023 14:25:11 GMT"},
    {"last-modified", "Thu, 02 Jun 2016 06:01:08 GMT"},
    {"cf-cache-status", "DYNAMIC"},
    {"report-to",
     "{\"endpoints\":[{\"url\":\"https:\\/\\/a.nel.cloudflare.com\\/report\\/v3?s=OW%2BJhOzTmxq4FGquM7w7bvkDLoryGQY9elB6ajNGx6Wgw0%2BjJechCF9vurIyh1V8rJ%2F0O6KL%2B36xUILE8SICSy1o0O1%2FrR2lx0XHgsN0ZWhBXsWf81OnlHM6ITw%3D\"}],\"group\":\"cf-nel\",\"max_age\":604800}"},
    {"nel",
     "{\"success_fraction\":0,\"report_to\":\"cf-nel\",\"max_age\":604800}"},
    {"cf-ray", "7bbe7a35ea419bc2-FRA"},
    {"alt-svc", "h3=\":443\"; ma=86400, h3-29=\":443\"; ma=86400"},
    {"content-length", "204"}
  ],
  body: "<html><head><title>Vous Etes Perdu ?</title></head><body><h1>Perdu sur l'Internet ?</h1><h2>Pas de panique, on va vous aider</h2><strong><pre>    * <----- vous &ecirc;tes ici</pre></strong></body></html>\n",
  status: 200,
  opts: [],
  __module__: Tesla,
  __client__: %Tesla.Client{
    fun: nil,
    pre: [{TeslaHTTPCache, :call, [%{store: :http_cache_store_process}]}],
    post: [],
    adapter: nil
  }
}
iex> Tesla.get!(client, "http://perdu.com")
%Tesla.Env{
  method: :get,
  url: "http://perdu.com",
  query: [],
  headers: [
    {"cache-control", "max-age=600"},
    {"date", "Sat, 22 Apr 2023 14:15:11 GMT"},
    {"etag", "W/\"cc-5344555136fe9-gzip\""},
    {"server", "cloudflare"},
    {"vary", "Accept-Encoding,User-Agent"},
    {"content-type", "text/html"},
    {"expires", "Sat, 22 Apr 2023 14:25:11 GMT"},
    {"last-modified", "Thu, 02 Jun 2016 06:01:08 GMT"},
    {"cf-cache-status", "DYNAMIC"},
    {"report-to",
     "{\"endpoints\":[{\"url\":\"https:\\/\\/a.nel.cloudflare.com\\/report\\/v3?s=OW%2BJhOzTmxq4FGquM7w7bvkDLoryGQY9elB6ajNGx6Wgw0%2BjJechCF9vurIyh1V8rJ%2F0O6KL%2B36xUILE8SICSy1o0O1%2FrR2lx0XHgsN0ZWhBXsWf81OnlHM6ITw%3D\"}],\"group\":\"cf-nel\",\"max_age\":604800}"},
    {"nel",
     "{\"success_fraction\":0,\"report_to\":\"cf-nel\",\"max_age\":604800}"},
    {"cf-ray", "7bbe7a35ea419bc2-FRA"},
    {"alt-svc", "h3=\":443\"; ma=86400, h3-29=\":443\"; ma=86400"},
    {"content-length", "204"},
    {"age", "8"}
  ],
  body: "<html><head><title>Vous Etes Perdu ?</title></head><body><h1>Perdu sur l'Internet ?</h1><h2>Pas de panique, on va vous aider</h2><strong><pre>    * <----- vous &ecirc;tes ici</pre></strong></body></html>\n",
  status: 200,
  opts: [],
  __module__: Tesla,
  __client__: %Tesla.Client{
    fun: nil,
    pre: [{TeslaHTTPCache, :call, [%{store: :http_cache_store_process}]}],
    post: [],
    adapter: nil
  }
}
iex> Tesla.get!(client, "http://perdu.com", headers: [{"range", "bytes=12-43"}])
%Tesla.Env{
  method: :get,
  url: "http://perdu.com",
  query: [],
  headers: [
    {"cache-control", "max-age=600"},
    {"date", "Sat, 22 Apr 2023 14:15:11 GMT"},
    {"etag", "W/\"cc-5344555136fe9-gzip\""},
    {"server", "cloudflare"},
    {"vary", "Accept-Encoding,User-Agent"},
    {"content-type", "text/html"},
    {"expires", "Sat, 22 Apr 2023 14:25:11 GMT"},
    {"last-modified", "Thu, 02 Jun 2016 06:01:08 GMT"},
    {"cf-cache-status", "DYNAMIC"},
    {"report-to",
     "{\"endpoints\":[{\"url\":\"https:\\/\\/a.nel.cloudflare.com\\/report\\/v3?s=OW%2BJhOzTmxq4FGquM7w7bvkDLoryGQY9elB6ajNGx6Wgw0%2BjJechCF9vurIyh1V8rJ%2F0O6KL%2B36xUILE8SICSy1o0O1%2FrR2lx0XHgsN0ZWhBXsWf81OnlHM6ITw%3D\"}],\"group\":\"cf-nel\",\"max_age\":604800}"},
    {"nel",
     "{\"success_fraction\":0,\"report_to\":\"cf-nel\",\"max_age\":604800}"},
    {"cf-ray", "7bbe7a35ea419bc2-FRA"},
    {"alt-svc", "h3=\":443\"; ma=86400, h3-29=\":443\"; ma=86400"},
    {"content-range", "bytes 12-43/204"},
    {"content-length", "32"},
    {"age", "22"}
  ],
  body: "<title>Vous Etes Perdu ?</title>",
  status: 206,
  opts: [],
  __module__: Tesla,
  __client__: %Tesla.Client{
    fun: nil,
    pre: [{TeslaHTTPCache, :call, [%{store: :http_cache_store_process}]}],
    post: [],
    adapter: nil
  }
}
iex> Tesla.get!(client, "http://perdu.com", headers: [{"cache-control", "no-cache"}])
%Tesla.Env{
  method: :get,
  url: "http://perdu.com",
  query: [],
  headers: [
    {"cache-control", "max-age=600"},
    {"date", "Sat, 22 Apr 2023 14:15:46 GMT"},
    {"etag", "W/\"cc-5344555136fe9-gzip\""},
    {"server", "cloudflare"},
    {"vary", "Accept-Encoding,User-Agent"},
    {"content-type", "text/html"},
    {"expires", "Sat, 22 Apr 2023 14:25:46 GMT"},
    {"last-modified", "Thu, 02 Jun 2016 06:01:08 GMT"},
    {"cf-cache-status", "DYNAMIC"},
    {"report-to",
     "{\"endpoints\":[{\"url\":\"https:\\/\\/a.nel.cloudflare.com\\/report\\/v3?s=3gbcT%2Bp7OxvokGPjTitRoTA9KyQOcbn6z1EG5jp2%2Frvg%2FqA%2Bi0CZgDK0O7VNSB6c5UIPsilr%2BMysTPCgi8ocxYYCsMhc82q4e7EP4nAI5zYYuJhmMGFXTeSjWMI%3D\"}],\"group\":\"cf-nel\",\"max_age\":604800}"},
    {"nel",
     "{\"success_fraction\":0,\"report_to\":\"cf-nel\",\"max_age\":604800}"},
    {"cf-ray", "7bbe7b10f8619bc2-FRA"},
    {"alt-svc", "h3=\":443\"; ma=86400, h3-29=\":443\"; ma=86400"},
    {"content-length", "204"}
  ],
  body: "<html><head><title>Vous Etes Perdu ?</title></head><body><h1>Perdu sur l'Internet ?</h1><h2>Pas de panique, on va vous aider</h2><strong><pre>    * <----- vous &ecirc;tes ici</pre></strong></body></html>\n",
  status: 200,
  opts: [],
  __module__: Tesla,
  __client__: %Tesla.Client{
    fun: nil,
    pre: [{TeslaHTTPCache, :call, [%{store: :http_cache_store_process}]}],
    post: [],
    adapter: nil
  }
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
