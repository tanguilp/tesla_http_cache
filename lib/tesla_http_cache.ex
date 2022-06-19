defmodule TeslaHTTPCache do
  @moduledoc """
  Documentation for `TeslaHTTPCache`.
  """

  @behaviour Tesla.Middleware

  defmodule InvalidBodyError do
    defexception [:message]

    @impl true
    def message(_), do: """
    TeslaHTTPCache received invalid body. Body must be `iodata()` or `nil`

    For requests, body must be encoded before calling this middleware (for
    example encoded to JSON) and for responses, the body must be decoded
    after (for instance, decoded to Elixir from a JSON string).
    """
  end

  @impl true
  def call(env, next, opts) do
    request = to_http_cache_request(env)

    case :http_cache.get(request, opts) do
      {:fresh, _} = response ->
        return_cached_response(response, env, opts)

      {:stale, _} = response ->
        return_cached_response(response, env, opts)

      {:must_revalidate, _} = response ->
        revalidate(request, response, env, next, opts)

      :miss ->
        :telemetry.execute([:tesla_http_cache, :miss], %{})

        with {:ok, env} <- Tesla.run(env, next) do
          {:ok, cache_new_response(request, env, opts)}
        end
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
    env
    |> add_validator(cached_headers, "last-modified", "if-modified-since")
    |> add_validator(cached_headers, "etag", "if-none-match")
    |> Tesla.run(next)
    |> case do
      {:ok, %Tesla.Env{status: 304} = env} ->
        :telemetry.execute([:tesla_http_cache, :hit], %{}, %{freshness: :revalidated})

        {:ok, cache_revalidated_response(request, env, revalidated_response, opts)}

      {:ok, env} ->
        :telemetry.execute([:tesla_http_cache, :miss], %{})

        {:ok, cache_new_response(request, env, opts)}

      {:error, _} = error ->
        error
    end
  end

  defp return_cached_response({freshness, {response_ref, response}}, env, opts) do
    :http_cache.notify_response_used(response_ref, opts)
    :telemetry.execute([:tesla_http_cache, :hit], %{}, %{freshness: freshness})

    {:ok, to_tesla_response(env, response)}
  end

  defp to_http_cache_request(env) do
    {
      env.method |> to_string() |> String.upcase(),
      env.url,
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

  defp cache_new_response(request, env, opts) do
    case :http_cache.cache(request, to_http_cache_response(env), opts) do
      {:ok, response} ->
        to_tesla_response(env, response)

      :not_cacheable ->
        env
    end
  end

  defp cache_revalidated_response(request, env, revalidated_response, opts) do
    case :http_cache.cache(request, to_http_cache_response(env), revalidated_response, opts) do
      {:ok, response} ->
        to_tesla_response(env, response)

      :not_cacheable ->
        env
    end
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
end
