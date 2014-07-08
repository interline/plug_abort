defmodule AbortTest do
  use ExUnit.Case
  use Plug.Test

  import Abort.Util

  defmodule JsonPlug do
    use Plug.Router
    import Abort

    plug Abort.Plug, :json
    plug :match
    plug :dispatch

    get "/:code" do
      abort! int(code)
    end

    get "/:code/:message" do
      abort! int(code), message
    end

    defp int(code) do
      {code, _} = Integer.parse(code)
      code
    end
  end

  defmodule TextPlug do
    use Plug.Router
    import Abort

    plug Abort.Plug, :text
    plug :match
    plug :dispatch

    get "/:code" do
      abort! int(code)
    end

    get "/:code/:message" do
      abort! int(code), message
    end

    defp int(code) do
      {code, _} = Integer.parse(code)
      code
    end
  end

  test :abort_json do
    Enum.each error_codes, fn code ->
      message = status_message(code)
      conn = conn(:get, "/#{code}") |> call_json
      assert conn.status == code
      assert %{"code" => ^code, "error" => ^message} = Jazz.decode! conn.resp_body
    end
  end

  test :abort_text do
    Enum.each error_codes, fn code ->
      message = status_message(code)
      conn = conn(:get, "/#{code}") |> call_text
      assert conn.status == code
      assert "#{code} #{message}" == conn.resp_body
    end
  end

  defp call_text(conn) do
    TextPlug.call(conn, TextPlug.init([]))
  end
  defp call_json(conn) do
    JsonPlug.call(conn, JsonPlug.init([]))
  end
end
