Abort
=====

```elixir
defmodule Router do
  use Plug.Router
  import Abort

  plug Abort.Plug, :text
  plug :match
  plug :dispatch

  get "/" do
    abort! 401, unless: authorized(conn)

    ...
  end
end
```
