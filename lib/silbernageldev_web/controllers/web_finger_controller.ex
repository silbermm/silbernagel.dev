defmodule SilbernageldevWeb.Controllers.WebFingerController do
  use SilbernageldevWeb, :controller

  plug(ETag.Plug)

  plug(:resource_required)

  @aliases [
    "acct:matt@silbernagel.dev",
    "acct:ahappydeath@silbernagel.dev",
    "acct:ahappydeath@freeradical.zone"
  ]

  def finger(conn, %{"resource" => resource}) do
    case resource do
      r when r in @aliases ->
        data = %{
          subject: "acct:ahappydeath@silbernagel.dev",
          aliases: [
            "acct:ahappydeath@freeradical.zone",
            "https://freeradical.zone/@ahappydeath",
            "https://freeradical.zone/users/ahappydeath"
          ],
          links: [
            %{
              rel: "http://webfinger.net/rel/profile-page",
              type: "type/html",
              href: "https://freeradical.zone/@ahappydeath"
            },
            %{
              rel: "self",
              type: "application/activity+json",
              href: "https://freeradical.zone/users/ahappydeath"
            },
            %{
              rel: "self",
              href: "https://silbernagel.dev"
            },
            %{
              rel: "http://ostatus.org/schema/1.0/subscribe",
              template: "https://freeradical.zone/authorize_interaction?uri={uri}"
            }
          ]
        }

        response = Phoenix.json_library().encode_to_iodata!(data)

        conn
        |> put_resp_content_type("application/jrd+json")
        |> send_resp(200, response)

      "acct:silbernagel.dev@silbernagel.dev" ->
        redirect(conn, external: "https://fed.brid.gy#{conn.request_path}?#{conn.query_string}")

      _ ->
        send_resp(conn, :not_found, "")
    end
  end

  defp resource_required(%{query_params: %{"resource" => _}} = conn, _) do
    conn
  end

  defp resource_required(conn, _) do
    conn
    |> send_resp(:bad_request, "")
    |> halt()
  end
end
