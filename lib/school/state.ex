defmodule School.State do
  use GenServer

  alias School.Player
  alias School.Logic

  @max_active_rules 5
  @available_rules [
    :rule1,
    :rule2,
    :rule3,
    :rule4,
    :rule5,
    :rule6,
    :rule7,
    :rule8,
    :rule9,
    :rule10,
    :rule11,
    :rule12
  ]
  @max_game_time_seconds 240

  defstruct active_rules: [],
            players: [],
            current_game_time: 0

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %__MODULE__{}, name: __MODULE__)
  end

  @impl true
  def init(state) do
    {:ok, state}
  end

  def add_player(name, pid, avatar) do
    GenServer.call(__MODULE__, {:add_player, name, pid, avatar})
  end

  def player_ready(name) do
    GenServer.call(__MODULE__, {:player_ready, name})
  end

  def set_random_rule do
    GenServer.cast(__MODULE__, :set_random_rule)
  end

  def get_active_rules do
    GenServer.call(__MODULE__, :get_active_rules)
  end

  def update_player_score(pid, package, expected) do
    GenServer.call(__MODULE__, {:update_player_score, pid, package, expected})
  end

  @impl true
  def handle_call({:player_ready, name}, _from, state) do
    {[player], remaining_players} =
      Enum.split_with(state.players, fn player -> player.name == name end)

    readied_player = Map.put(player, :ready?, true)
    updated_player_list = [readied_player | remaining_players]
    all_ready? = Enum.all?(updated_player_list, fn player -> player.ready? end)

    {game_state, new_state} =
      if all_ready? do
        {:in_progress, start_match(state, updated_player_list)}
      else
        {:waiting, Map.put(state, :players, updated_player_list)}
      end

    # The player's score may have been reset by start_match, so reply with the
    # freshest copy.
    reply_player = Enum.find(new_state.players, fn player -> player.name == name end)

    Phoenix.PubSub.broadcast(
      School.PubSub,
      "game_room",
      {:update_player_list, sort_by_score(new_state.players)}
    )

    {:reply, {reply_player, game_state}, new_state}
  end

  @impl true
  def handle_call(:get_active_rules, _from, state) do
    {:reply, state.active_rules, state}
  end

  @impl true
  def handle_call({:update_player_score, pid, package, expected}, _from, state) do
    {[player], remaining_players} =
      Enum.split_with(state.players, fn player -> player.pid == pid end)

    {validation_result, validation_msg} =
      Logic.validate(package, state.active_rules)

    decision =
      if validation_result == expected,
        do: :correct,
        else: :incorrect

    score_delta =
      if decision == :correct,
        do: 1,
        else: -1

    new_score = max(player.score + score_delta, 0)

    updated_player = Map.put(player, :score, new_score)

    updated_player_list = [updated_player | remaining_players]

    Phoenix.PubSub.broadcast(
      School.PubSub,
      "game_room",
      {:update_player_list, sort_by_score(updated_player_list)}
    )

    new_state = Map.put(state, :players, updated_player_list)

    {:reply, {updated_player, decision, validation_msg}, new_state}
  end

  @impl true
  def handle_call({:add_player, name, pid, avatar}, _from, state) do
    Process.monitor(pid)

    new_player = %Player{
      pid: pid,
      name: name,
      avatar: avatar
    }

    updated_player_list = [new_player | state.players]
    new_state = Map.put(state, :players, updated_player_list)

    Phoenix.PubSub.broadcast(
      School.PubSub,
      "game_room",
      {:update_player_list, updated_player_list}
    )

    {:reply, new_player, new_state}
  end

  @impl true
  def handle_cast(:set_random_rule, state) do
    new_state = maybe_activate_random_rule(state)

    {:noreply, new_state}
  end

  @impl true
  def handle_info(:tick, state) do
    current_game_time = state.current_game_time

    if current_game_time > @max_game_time_seconds do
      end_match(state)
    else
      Process.send_after(self(), :tick, 1_000)

      Phoenix.PubSub.broadcast(
        School.PubSub,
        "game_room",
        {:tick_update, current_game_time}
      )

      state_with_new_rule =
        if rem(current_game_time, 30) == 0 do
          Phoenix.PubSub.broadcast(
            School.PubSub,
            "game_room",
            :update_rules
          )

          maybe_activate_random_rule(state)
        else
          state
        end

      new_state =
        Map.put(state_with_new_rule, :current_game_time, current_game_time + 1)

      {:noreply, new_state}
    end
  end

  # handle killed PID
  # {:DOWN, #Reference<0.4092222473.1123811329.133049>, :process, #PID<0.664.0>, {:shutdown, :closed}}
  @impl true
  def handle_info({:DOWN, _, _, pid, _}, state) do
    player_list = state.players
    updated_player_list = Enum.reject(player_list, fn player -> player.pid == pid end)
    new_state = Map.put(state, :players, updated_player_list)

    Phoenix.PubSub.broadcast(
      School.PubSub,
      "game_room",
      {:update_player_list, updated_player_list}
    )

    {:noreply, new_state}
  end

  def max_game_time do
    @max_game_time_seconds
  end

  defp maybe_activate_random_rule(state) do
    if length(state.active_rules) < @max_active_rules do
      activate_new_rule(state)
    else
      state
    end
  end

  defp activate_new_rule(state) do
    active_rules = state.active_rules

    new_rule =
      @available_rules
      |> Enum.reject(fn rule -> rule in active_rules end)
      |> Enum.random()

    new_state =
      Map.put(state, :active_rules, [new_rule | active_rules])

    new_state
  end

  defp sort_by_score(player_list) do
    Enum.sort(player_list, fn p1, p2 -> p1.score > p2.score end)
  end

  # Starts a fresh match: zero the clock, clear rules, reset everyone's score,
  # and kick off the tick loop.
  defp start_match(state, player_list) do
    Phoenix.PubSub.broadcast(
      School.PubSub,
      "game_room",
      {:game_start, :in_progress}
    )

    Process.send_after(self(), :tick, 1_000)

    fresh_players = Enum.map(player_list, fn player -> Map.put(player, :score, 0) end)

    state
    |> Map.put(:players, fresh_players)
    |> Map.put(:current_game_time, 0)
    |> Map.put(:active_rules, [])
  end

  # Ends the match: stop the tick (by not rescheduling) and mark every player
  # not-ready so each must opt into the next match individually.
  defp end_match(state) do
    unready_players = Enum.map(state.players, fn player -> Map.put(player, :ready?, false) end)

    Phoenix.PubSub.broadcast(
      School.PubSub,
      "game_room",
      {:game_ended, :ended}
    )

    Phoenix.PubSub.broadcast(
      School.PubSub,
      "game_room",
      {:update_player_list, sort_by_score(unready_players)}
    )

    {:noreply, Map.put(state, :players, unready_players)}
  end
end
