defmodule CoinsWeb.PageController do
  use CoinsWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
