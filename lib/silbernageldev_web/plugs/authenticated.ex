defmodule SilbernageldevWeb.Plugs.Authenticated do
  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _opts) do
    auth_header =
      Enum.find(conn.req_headers, fn
        {"authorization", _} -> true
        _ -> false
      end)

    case auth_header do
      nil ->
        conn
        |> send_resp(401, "Unauthenticated")
        |> halt()

      {_, "Bearer " <> token} ->
        case Phoenix.Token.verify(SilbernageldevWeb.Endpoint, "user_auth", token) do
          {:ok, %{email: email, id: id}} ->
            conn
            |> put_session(:email, email)
            |> put_session(:user_id, id)

          {:error, _} ->
            conn
            |> send_resp(401, "Unauthenticated")
            |> halt()
        end

      _ ->
        conn
        |> send_resp(401, "Unauthenticated")
        |> halt()
    end
  end
end
