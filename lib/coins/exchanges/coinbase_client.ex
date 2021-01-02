defmodule Coins.Exchanges.CoinbaseClient do
  @moduledoc false
  use GenServer
  require Logger

  @host "invalid-server"
  @port 443

  def start_link(init_opts, opts \\ []) do
    GenServer.start_link(__MODULE__, init_opts, opts)
  end

  @impl true
  def init(opts) do
    state = %{
      currency_pairs: opts,
      client: nil
    }

    {:ok, state, {:continue, :open}}
  end

  @impl true
  def handle_continue(:open, %{currency_pairs: pairs} = state) do
    client = open!()
    frame = ticker_frame(pairs)
    send_frame(client, frame)
    {:noreply, %{state | client: client}}
  end

  @impl true
  def handle_info({:gun_ws, _client, _ref, {:text, payload}}, state) do
    frame = Jason.decode!(payload)
    handle_ws_message(frame, state)
  end

  def handle_info(call, state) do
    Logger.info("Unknown info message: #{inspect(call)}")
    {:noreply, state}
  end

  def handle_ws_message(%{"type" => "ticker"} = frame, state) do
    Logger.debug("#{inspect(frame)}", label: "ticker")
    {:noreply, state}
  end

  def handle_ws_message(frame, state) do
    Logger.info("Unknown ws message: #{inspect(frame)}")
    {:noreply, state}
  end

  def open!(host \\ @host, port \\ @port, timeout \\ 10000) do
    hostname = String.to_charlist(host)
    opts = %{protocols: [:http]}

    {:ok, conn} = :gun.open(hostname, port, opts)
    Process.monitor(conn)

    {:ok, :http} = :gun.await_up(conn)
    :gun.ws_upgrade(conn, '/')

    receive do
      {:gun_upgrade, ^conn, _, _, _} ->
        conn
    after
      timeout ->
        raise "timeout"
    end
  end

  def send_frame(client, frame) do
    :gun.ws_send(client, {:binary, Jason.encode!(frame)})
  end

  def ticker_frame(ids \\ ["BTC-USD"]) do
    %{
      type: :subscribe,
      channels: [%{name: :ticker, product_ids: ids}]
    }
  end
end
