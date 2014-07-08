defmodule Abort do
  defmacro abort!(status, message \\ nil, opts \\ []) do
    if is_list(message) do
      opts = message
      message = nil
    end

    abort =
      if nil? message do
        quote do: {:abort, var!(conn), unquote(status)}
      else
        quote do: {:abort, var!(conn), unquote(status), unquote(message)}
      end

    expression = opts[:unless]

    if expression do
      quote do
        unless unquote(expression), do: throw unquote(abort)
      end
    else
      quote do: throw unquote(abort)
    end
  end
end

defmodule Abort.Util do

  status_messages =
    File.read!("error_codes")
    |> String.strip
    |> String.split("\n")
    |> Enum.map(&String.split(&1, ","))
    |> Enum.map(fn [code, message] ->
         {code, _} = Integer.parse(code)
         {code, message}
       end)

  status_message_quoted =
    Enum.map status_messages, fn {code, message} ->
       quote do
         def status_message(unquote(code)), do: unquote(message)
       end
     end

  Module.eval_quoted __MODULE__, status_message_quoted


  error_codes = status_messages |> Enum.map(&elem(&1, 0))
  error_codes_quoted =
    quote do
      def error_codes do
        unquote(error_codes)
      end
    end

  Module.eval_quoted __MODULE__, error_codes_quoted
end

defmodule Abort.Plug do
  @behaviour Plug.Wrapper

  import Plug.Conn
  import Abort.Util


  def init(content_type \\ :text) do
    unless content_type in [:text, :json] do
      raise ArgumentError, ":text or :json expected"
    end
    content_type
  end


  def wrap(conn, content_type, stack) do
    try do
      stack.(conn)
    catch
      {:abort, conn, status} ->
        send(conn, content_type, status, status_message(status))
      {:abort, conn, status, message} ->
        send(conn, content_type, status, message)
    end
  end


  defp send(conn, :text, status, message) do
    conn
    |> put_resp_content_type("text/plain")
    |> send_resp(status, "#{status} #{message}")
  end

  defp send(conn, :json, status, message) do
    error = %{error: message, code: status}
    conn |> put_resp_content_type("application/json") |> send_resp(status, Jazz.encode!(error))
  end
end
