defmodule SchoolWeb.MainLive do
  use SchoolWeb, :live_view

  alias School.Avatar
  alias School.Logic
  alias School.State

  import SchoolWeb.GameComponents

  @impl true
  def mount(_params, _session, socket) do
    package = Logic.generate_package()

    Phoenix.PubSub.subscribe(School.PubSub, "game_room")

    active_rules = State.get_active_rules()
    rule_descriptions = Logic.descriptions_by_rules(active_rules)

    new_socket =
      socket
      |> assign(:local_player, nil)
      |> assign(:package, package)
      |> assign(:timestamp, nil)
      |> assign(:validation_result, :correct)
      |> assign(:score_delta, 0)
      |> assign(:game_state, :waiting)
      |> assign(:active_rules, active_rules)
      |> assign(:rule_descriptions, rule_descriptions)
      |> assign(:score, 0)
      |> assign(:player_list, [])
      |> assign(:xray_active, false)
      |> assign(:rules_hidden, false)
      |> assign(:blackout_remaining, 0)
      |> assign(:avatar, Avatar.default())
      |> assign(:avatar_open, nil)
      |> assign(:rush_hour, false)

    {:ok, new_socket}
  end

  @impl true
  def handle_event("join", %{"name" => name}, socket) do
    local_player = State.add_player(name, self(), socket.assigns.avatar)

    new_socket =
      socket
      |> assign(:local_player, local_player)

    {:noreply, new_socket}
  end

  @impl true
  def handle_event("avatar_set", %{"field" => field, "index" => index}, socket) do
    avatar =
      Avatar.set(socket.assigns.avatar, String.to_existing_atom(field), String.to_integer(index))

    new_socket =
      socket
      |> assign(:avatar, avatar)
      |> assign(:avatar_open, nil)

    {:noreply, new_socket}
  end

  @impl true
  def handle_event("avatar_toggle", %{"field" => field}, socket) do
    field = String.to_existing_atom(field)
    open = if socket.assigns.avatar_open == field, do: nil, else: field

    {:noreply, assign(socket, :avatar_open, open)}
  end

  @impl true
  def handle_event("ready", _params, socket) do
    local_player = socket.assigns.local_player
    {updated_local_player, _game_state} = State.player_ready(local_player.name)

    new_socket =
      socket
      |> assign(:local_player, updated_local_player)

    {:noreply, new_socket}
  end

  @impl true
  def handle_event("new_match", _params, socket) do
    local_player = Map.put(socket.assigns.local_player, :ready?, false)

    new_socket =
      socket
      |> assign(:local_player, local_player)
      |> assign(:game_state, :waiting)
      |> assign(:score, 0)

    {:noreply, new_socket}
  end

  @impl true
  def handle_event("toggle_xray", _params, socket) do
    {:noreply, assign(socket, :xray_active, !socket.assigns.xray_active)}
  end

  @impl true
  def handle_event("decline", _params, socket) do
    new_socket = validation("swipe-left", :invalid, socket)

    {:noreply, new_socket}
  end

  @impl true
  def handle_event("approve", _params, socket) do
    new_socket = validation("swipe-right", :valid, socket)

    {:noreply, new_socket}
  end

  @impl true
  def handle_info(:next_package, socket) do
    package = Logic.generate_package()

    new_socket =
      socket
      |> assign(:package, package)
      |> assign(:xray_active, false)
      |> push_event("reset-package-card", %{})

    {:noreply, new_socket}
  end

  @impl true
  def handle_info({:game_start, game_state}, socket) do
    new_socket =
      socket
      |> assign(:game_state, game_state)

    {:noreply, new_socket}
  end

  @impl true
  def handle_info({:game_ended, game_state}, socket) do
    new_socket =
      socket
      |> assign(:game_state, game_state)

    {:noreply, new_socket}
  end

  @impl true
  def handle_info({:tick_update, current_game_time}, socket) do
    width = build_game_time_loading_bar(current_game_time)

    is_rush = current_game_time >= 210

    new_socket =
      socket
      |> assign(:rush_hour, is_rush)
      |> push_event("timer-tick", %{time: current_game_time, width: width})

    {:noreply, new_socket}
  end

  @impl true
  def handle_info(:update_rules, socket) do
    active_rules = State.get_active_rules()
    rule_descriptions = Logic.descriptions_by_rules(active_rules)

    new_socket =
      socket
      |> assign(:rule_descriptions, rule_descriptions)
      |> assign(:active_rules, active_rules)

    {:noreply, new_socket}
  end

  def handle_info({:update_player_list, updated_player_list}, socket) do
    new_socket =
      socket
      |> assign(:player_list, updated_player_list)

    {:noreply, new_socket}
  end

  @impl true
  def handle_info(:blackout_tick, socket) do
    remaining = socket.assigns.blackout_remaining - 1

    new_socket =
      if remaining <= 0 do
        socket
        |> assign(:rules_hidden, false)
        |> assign(:blackout_remaining, 0)
      else
        Process.send_after(self(), :blackout_tick, 1_000)
        assign(socket, :blackout_remaining, remaining)
      end

    {:noreply, new_socket}
  end

  defp validation(swipe_direction, expected, socket) do
    package = socket.assigns.package

    {updated_player, decision, validation_msg, score_delta} =
      State.update_player_score(self(), package, expected)

    fatal_error = decision == :incorrect and package.packet_contents in [:drugs, :guns]
    already_hidden = socket.assigns.rules_hidden

    if fatal_error and not already_hidden do
      Process.send_after(self(), :blackout_tick, 1_000)
    end

    blackout_remaining =
      if fatal_error, do: 15, else: socket.assigns.blackout_remaining

    new_socket =
      socket
      |> assign(:validation_result, decision)
      |> assign(:validation_msg, validation_msg)
      |> assign(:score_delta, score_delta)
      |> assign(:local_player, updated_player)
      |> assign(:score, updated_player.score)
      |> assign(:rules_hidden, fatal_error or already_hidden)
      |> assign(:blackout_remaining, blackout_remaining)
      |> push_event(swipe_direction, %{})

    Process.send_after(self(), :next_package, 1_000)

    new_socket
  end

  def build_game_time_loading_bar(game_time) do
    max_game_time = State.max_game_time()
    game_time / max_game_time * 100
  end
end
