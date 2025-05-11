defmodule TeslaHTTPCache do
  @moduledoc """
  Middleware implementation

  Refer to the README for more information.
  """

  @behaviour Tesla.Middleware

  @default_opts %{auto_accept_encoding: true, auto_compress: true, type: :private}

  defmodule InvalidBodyError do
    @moduledoc """
    Error raised when a downstream middleware returns a non-binary and non-IOlist response body
    """

    defexception [:message]

    @impl true
    def message(_),
      do: """
      TeslaHTTPCache received invalid body. Body must be `iodata()` or `nil`

      For requests, body must be encoded before calling this middleware (for
      example encoded to JSON) and for responses, the body must be decoded
      after (for instance, decoded to Elixir from a JSON string).
      """
  end

  @impl true
  def call(env, next, opts) do
    opts = init_opts(opts)

    do_call(env, next, opts)
  end

  defp do_call(env, next, opts) do
    request = to_http_cache_request(env)

    case :http_cache.get(request, opts) do
      {:fresh, _} = response ->
        return_cached_response(response, env, opts)

      {:stale, _} = response ->
        return_cached_response(response, env, opts)

      {:must_revalidate, _} = response ->
        :http_cache.notify_downloading(request, self(), opts)

        revalidate(request, response, env, next, opts)

      :miss ->
        :telemetry.execute([:tesla_http_cache, :miss], %{env: env})

        :http_cache.notify_downloading(request, self(), opts)

        opts = Map.put(opts, :request_time, now())

        env
        |> Tesla.run(next)
        |> handle_response(request, env, opts)
    end
  rescue
    e in InvalidBodyError ->
      raise e

    _ ->
      Tesla.run(env, next)
  end

  defp revalidate(
         request,
         {_, {_, {_, cached_headers, _} = revalidated_response}},
         env,
         next,
         opts
       ) do
    opts = Map.put(opts, :request_time, now())

    env
    |> add_validator(cached_headers, "last-modified", "if-modified-since")
    |> add_validator(cached_headers, "etag", "if-none-match")
    |> Tesla.run(next)
    |> handle_response(request, revalidated_response, env, opts)
  end

  defp handle_response(result, http_cache_req, http_cache_revalidated_resp \\ nil, req_env, opts)

  defp handle_response(
         {:ok, %Tesla.Env{status: 304} = resp_env},
         http_cache_req,
         http_cache_revalidated_resp,
         _req_env,
         opts
       ) do
    :telemetry.execute([:tesla_http_cache, :hit], %{}, %{freshness: :revalidated, env: resp_env})

    case :http_cache.cache(
           http_cache_req,
           to_http_cache_response(resp_env),
           http_cache_revalidated_resp,
           opts
         ) do
      {:ok, http_cache_resp} ->
        {:ok, to_tesla_response(resp_env, http_cache_resp)}

      :not_cacheable ->
        {:ok, resp_env}
    end
  end

  defp handle_response(
         {:ok, %Tesla.Env{} = resp_env},
         http_cache_req,
         _http_cache_revalidated_resp,
         _req_env,
         opts
       ) do
    case :http_cache.cache(http_cache_req, to_http_cache_response(resp_env), opts) do
      {:ok, http_cache_resp} ->
        {:ok, to_tesla_response(resp_env, http_cache_resp)}

      {:not_cacheable, {response_ref, response}} ->
        return_cached_response({:stale, {response_ref, response}}, resp_env, opts)

      :not_cacheable ->
        {:ok, resp_env}
    end
  end

  defp handle_response(
         {:error, _reason} = error,
         http_cache_req,
         _http_cache_revalidated_resp,
         req_env,
         opts
       ) do
    case :http_cache.cache(http_cache_req, {502, [], ""}, opts) do
      # stale-if-error case
      {:not_cacheable, {response_ref, response}} ->
        return_cached_response({:stale, {response_ref, response}}, req_env, opts)

      :not_cacheable ->
        error
    end
  end

  defp return_cached_response({freshness, {response_ref, response}}, env, opts) do
    :http_cache.notify_response_used(response_ref, opts)
    :telemetry.execute([:tesla_http_cache, :hit], %{}, %{freshness: freshness, env: env})

    {:ok, to_tesla_response(env, response)}
  end

  defp to_http_cache_request(env) do
    {
      env.method |> to_string() |> String.upcase(),
      Tesla.build_url(env.url, env.query),
      env.headers,
      (env.body || "") |> :erlang.iolist_to_binary()
    }
  rescue
    _ ->
      raise %__MODULE__.InvalidBodyError{}
  end

  defp to_http_cache_response(env) do
    {
      env.status,
      env.headers,
      (env.body || "") |> :erlang.iolist_to_binary()
    }
  rescue
    _ ->
      raise %__MODULE__.InvalidBodyError{}
  end

  defp to_tesla_response(env, {status, resp_headers, {:sendfile, offset, :all, path}}) do
    file_size = File.stat!(path).size

    to_tesla_response(env, {status, resp_headers, {:sendfile, offset, file_size, path}})
  end

  defp to_tesla_response(env, {status, resp_headers, {:sendfile, offset, length, path}}) do
    file = File.open!(path, [:read, :raw, :binary])

    try do
      {:ok, content} = :file.pread(file, offset, length)
      %Tesla.Env{env | status: status, headers: resp_headers, body: content}
    after
      File.close(file)
    end
  end

  defp to_tesla_response(env, {status, resp_headers, body}) do
    %Tesla.Env{env | status: status, headers: resp_headers, body: :erlang.iolist_to_binary(body)}
  end

  defp add_validator(env, cached_headers, validator, condition_header) do
    cached_headers
    |> Enum.find(fn {header_name, _} -> String.downcase(header_name) == validator end)
    |> case do
      {_, header_value} ->
        Tesla.put_header(env, condition_header, header_value)

      nil ->
        env
    end
  end

  defp init_opts(%{store: _} = opts) do
    Map.merge(@default_opts, opts)
  end

  defp init_opts(_) do
    raise("Missing `store` http_cache option")
  end

  defp now(), do: :os.system_time(:second)
end
