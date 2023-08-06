defmodule SilbernageldevWeb.Controllers.CertController do
  use SilbernageldevWeb, :controller

  def verify(conn, _) do
    send_resp(conn, :ok, "nopWVid1ovI83c7sz4E9L7lb_IuUN9I-TVXAE9NpB98.ZLdh8TvT3EaDOp9-q9pAJDa215wqN_uyS1xlwz8utjg")
  end
end
