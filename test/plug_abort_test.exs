defmodule AbortTest do
  use ExUnit.Case
  use Plug.Test

  import Abort.Util

  defmodule TestPlug do
    defmacro __using__(type) do
      quote do
        use Plug.Builder
        import Abort

        plug Abort.Plug, unquote(type)
        plug :handle

        def handle(%Conn{path_info: [code]}, _) do
          abort! int(code)
        end

        def handle(%Conn{path_info: [code, message]}, _) do
          abort! int(code), message
        end

        defp int(code) do
          {code, _} = Integer.parse(code)
          code
        end
      end
    end
  end

  defmodule JsonPlug do
    use TestPlug, :json
  end

  defmodule TextPlug do
    use TestPlug, :text
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
