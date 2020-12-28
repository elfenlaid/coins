defmodule Coins.Exchanges.CoinbaseClient do
  @moduledoc false

  @host "ws-feed.pro.coinbase.com"
  @port 443

  def connect!(host \\ @host, port \\ @port) do
    {:ok, conn} = :gun.open(String.to_charlist(host), port, %{protocols: [:http]})
    {:ok, :http} = :gun.await_up(conn)
    :gun.ws_upgrade(conn, '/')

    receive do
      {:gun_upgrade, ^conn, _, _, _} ->
        conn
    after
      10000 ->
        raise "timeout"
    end
  end

  def send(client, frame) do
    :gun.ws_send(client, {:binary, Jason.encode!(frame)})
  end

  def ticker_frame(ids \\ ["BTC-USD"]) do
    %{
      type: :subscribe,
      channels: [%{name: :ticker, product_ids: ids}]
    }
  end
end
