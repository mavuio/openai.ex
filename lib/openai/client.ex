defmodule OpenAI.Client do
  @moduledoc false
  alias OpenAI.Config
  use HTTPoison.Base
  
  @timeout 15000

  def process_url(url), do: Config.api_url() <> url

  def process_response_body(body), do: JSON.decode(body)

  def handle_response(httpoison_response) do
    case httpoison_response do
      {:ok, %HTTPoison.Response{status_code: 200, body: {:ok, body}}} ->
        res =
          body
          |> Enum.map(fn {k, v} -> {String.to_atom(k), v} end)
          |> Map.new()

        {:ok, res}

      {:ok, %HTTPoison.Response{body: {:ok, body}}} ->
        {:error, body}

      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, reason}
    end
  end

  def add_organization_header(headers) do
    unless Config.org_key() == nil do
      headers
      |> Enum.concat({"OpenAI-Organization", Config.org_key()})
    end

    headers
  end

  def request_headers do
    [
      {"Authorization", "Bearer #{Config.api_key()}"},
      {"Content-type", "application/json"}
    ]
    |> add_organization_header()
  end

  def api_get(url) do
    url
    |> get(request_headers(), [recv_timeout: @timeout])
    |> handle_response()
  end

  def api_post(url, params) do
    body =
      params
      |> Enum.into(%{})
      |> JSON.Encoder.encode()
      |> elem(1)

    url
    |> post(body, request_headers(), [recv_timeout: @timeout])
    |> handle_response()
  end
end
