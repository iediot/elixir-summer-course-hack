defmodule SchoolWeb.GameComponents do
  use Phoenix.Component

  alias School.Avatar

  @doc """
  Renders a player's avatar as inline SVG, built from a `School.Avatar` config
  map. Scales to any `size` (px), so the same component serves the header
  badge and the small leaderboard rows.
  """
  attr :config, :map, default: nil
  attr :size, :integer, default: 40

  def avatar(assigns) do
    config = assigns.config || Avatar.default()

    assigns =
      assigns
      |> assign(:skin, Avatar.skin(config.skin))
      |> assign(:accent, Avatar.accent(config.accent))
      |> assign(:hair_style, Avatar.hair_style(config.hair_style).style)
      |> assign(:hair_color, Avatar.hair_color(config.hair_color).color)

    ~H"""
    <svg
      width={@size}
      height={@size}
      viewBox="0 0 100 100"
      class="avatar-svg"
      role="img"
      aria-label="Player avatar"
    >
      <circle cx="50" cy="50" r="50" fill={@accent} />
      <circle cx="50" cy="54" r="30" fill={@skin} />
      <circle cx="40" cy="50" r="3.2" fill="#222" />
      <circle cx="60" cy="50" r="3.2" fill="#222" />
      <path
        d="M41 63 Q50 70 59 63"
        stroke="#222"
        stroke-width="2.5"
        fill="none"
        stroke-linecap="round"
      />
      <%= case @hair_style do %>
        <% :none -> %>
        <% :short -> %>
          <path
            d="M21 51 Q21 22 50 22 Q79 22 79 51 Q70 37 50 37 Q30 37 21 51 Z"
            fill={@hair_color}
          />
        <% :buzz -> %>
          <path
            d="M24 47 Q26 26 50 26 Q74 26 76 47 Q68 41 50 41 Q32 41 24 47 Z"
            fill={@hair_color}
            opacity="0.85"
          />
        <% :bun -> %>
          <circle cx="50" cy="19" r="8" fill={@hair_color} />
          <path
            d="M21 51 Q21 22 50 22 Q79 22 79 51 Q70 37 50 37 Q30 37 21 51 Z"
            fill={@hair_color}
          />
        <% :mohawk -> %>
          <path d="M44 16 Q50 4 56 16 L56 40 Q50 35 44 40 Z" fill={@hair_color} />
        <% :long -> %>
          <path
            d="M19 52 Q19 22 50 22 Q81 22 81 52 Q72 37 50 37 Q28 37 19 52 Z"
            fill={@hair_color}
          />
          <path d="M20 50 Q15 72 24 80 L31 71 Q25 60 27 50 Z" fill={@hair_color} />
          <path d="M80 50 Q85 72 76 80 L69 71 Q75 60 73 50 Z" fill={@hair_color} />
      <% end %>
    </svg>
    """
  end

  attr :player_name, :string, required: true
  attr :score, :integer, required: true
  attr :avatar, :map, required: true

  def score_banner(assigns) do
    ~H"""
    <div class="player-score-bar">
      <div class="player-identity">
        <div class="player-avatar">
          <.avatar config={@avatar} size={36} />
        </div>
        <div>
          <div class="player-name">Inspector {@player_name}</div>
          <div class="player-role">Senior Postal Officer</div>
        </div>
      </div>
      <div class="score-display">
        <span class="score-label">Score</span>
        <span class="score-value">{@score}</span>
        <span class="score-unit">pts</span>
      </div>
    </div>
    """
  end

  def match_time_remaining(assigns) do
    ~H"""
    <div class="card-timer-section">
      <span class="card-timer-label">Match time remaining</span>
      <div class="card-timer-track">
        <div class="card-timer-fill" style="width: 0%;"></div>
      </div>
      <span class="card-timer-seconds">0s</span>
    </div>
    """
  end

  attr :package, :map, required: true
  attr :timestamp, :integer, required: true
  attr :validation_result, :atom, required: true
  attr :score_delta, :integer, required: true
  attr :xray_active, :boolean, required: true

  def package_inspection_form(assigns) do
    ~H"""
    <div class="card-reveal-wrapper">
      <%= case @validation_result do %>
        <% :correct -> %>
          <div class="stamp-result" id={"card-#{@timestamp}"}>
            <div class="stamp-mark approved">
              <span class="stamp-label">Approved</span>
              <span class="stamp-points">{format_points(@score_delta)}</span>
            </div>
          </div>
        <% :incorrect -> %>
          <div class="stamp-result" id={"card-#{@timestamp}"}>
            <div class="stamp-mark rejected">
              <span class="stamp-label">Rejected</span>
              <span class="stamp-points">{format_points(@score_delta)}</span>
            </div>
          </div>
        <% nil -> %>
          <div></div>
      <% end %>

      <div class="package-card">
        <div class="card-header">
          <div class="card-title-group">
            <div class="card-title">Package Inspection Form</div>
            <div class="card-id">PKG-{@timestamp}</div>
          </div>
          <div class="card-stamp">
            <span class="card-stamp-text">Postage</span>
            <span class="card-stamp-value">€4.50</span>
            <span class="card-stamp-text">Paid</span>
          </div>
        </div>

        <div class="package-fields">
          <div class="field">
            <div class="field-label">Package Type</div>
            <div class="field-value type-badge">{capitalise(@package.type)}</div>
          </div>
          <div class="field">
            <div class="field-label">Weight</div>
            <div class="field-value">{@package.weight}g</div>
          </div>
          <div class="field">
            <div class="field-label">Destination</div>
            <div class="field-value">{capitalise(@package.destination)}</div>
          </div>
          <div class="field">
            <div class="field-label">Shipping Class</div>
            <div class="field-value">{capitalise(@package.shipping_class)}</div>
          </div>
          <div class="field">
            <div class="field-label">Declared Value</div>
            <div class="field-value">{@package.declared_value}</div>
          </div>
          <div class="field">
            <div class="field-label">Contents</div>
            <div
              class="field-value"
              style={unless @xray_active, do: "filter: blur(4px); user-select: none;"}
            >
              {if @xray_active, do: capitalise(@package.packet_contents), else: "Unknown"}
            </div>
            <button phx-click="toggle_xray" class="xray-btn">
              {if @xray_active, do: "Hide", else: "X-Ray"}
            </button>
          </div>
        </div>

        <div class="package-checks">
          <span :if={@package.has_customs_form} class="check-tag has">
            <span class="check-dot"></span> Customs Form
          </span>
          <span :if={@package.has_insurance} class="check-tag has">
            <span class="check-dot"></span> Insurance
          </span>
          <span :if={@package.has_fragile_sticker} class="check-tag has">
            <span class="check-dot"></span> Fragile Sticker
          </span>
          <span
            :if={@package.packet_contents == :drugs and @package.has_medical_reasoning}
            class="check-tag has"
          >
            <span class="check-dot"></span> Medical Reasoning
          </span>
          <span
            :if={@package.packet_contents == :guns and @package.has_military_reasoning}
            class="check-tag has"
          >
            <span class="check-dot"></span> Military Reasoning
          </span>
        </div>

        <div class="card-actions">
          <button phx-click="decline" class="btn btn-decline">
            <span class="btn-icon">✕</span> Decline
          </button>
          <button phx-click="approve" class="btn btn-approve">
            <span class="btn-icon">✓</span> Approve
          </button>
        </div>
      </div>
    </div>
    """
  end

  attr :field, :string, required: true
  attr :label, :string, required: true
  attr :options, :list, required: true
  attr :selected, :integer, required: true
  attr :kind, :atom, required: true
  attr :open, :boolean, required: true

  def avatar_dropdown(assigns) do
    assigns = assign(assigns, :current, Enum.at(assigns.options, assigns.selected))

    ~H"""
    <div class={["avatar-dropdown", @open && "open"]}>
      <span class="avatar-row-label">{@label}</span>

      <button
        type="button"
        class="avatar-trigger"
        phx-click="avatar_toggle"
        phx-value-field={@field}
      >
        <.avatar_option_label kind={@kind} option={@current} />
        <span class="avatar-caret">▾</span>
      </button>

      <div :if={@open} class={["avatar-menu", @kind == :color && "is-grid"]}>
        <button
          :for={{opt, index} <- Enum.with_index(@options)}
          type="button"
          phx-click="avatar_set"
          phx-value-field={@field}
          phx-value-index={index}
          class={["avatar-option", index == @selected && "selected"]}
        >
          <.avatar_option_label kind={@kind} option={opt} />
        </button>
      </div>
    </div>
    """
  end

  attr :kind, :atom, required: true
  attr :option, :any, required: true

  defp avatar_option_label(assigns) do
    ~H"""
    <%= case @kind do %>
      <% :color -> %>
        <span class="swatch-chip" style={"background-color: #{@option}"}></span>
      <% :swatch_named -> %>
        <span class="swatch-chip" style={"background-color: #{@option.color}"}></span>
        <span class="swatch-name">{@option.name}</span>
      <% :text -> %>
        <span class="swatch-name">{@option.label}</span>
    <% end %>
    """
  end

  attr :local_player, :map, default: nil
  attr :avatar, :map, required: true
  attr :avatar_open, :atom, default: nil

  def ready_section(assigns) do
    ~H"""
    <div class="ready-section">
      <span class="ready-title">Report for Duty</span>

      <%= if @local_player do %>
        <div class="avatar-preview">
          <.avatar config={@local_player.avatar} size={96} />
        </div>

        <.form for={%{}} phx-submit="ready">
          <div class="ready-input-group">
            <label class="player-name" for="inspector-name">{@local_player.name}</label>
          </div>

          <%= if @local_player.ready? do %>
            ✓ Ready
          <% else %>
            <button class="btn">
              Ready
            </button>
          <% end %>
        </.form>
      <% else %>
        <.form for={%{}} phx-submit="join" class="join-form">
          <div class="avatar-customizer">
            <div class="avatar-preview">
              <.avatar config={@avatar} size={96} />
            </div>
            <.avatar_dropdown
              field="skin"
              label="Skin"
              options={Avatar.skins()}
              selected={@avatar.skin}
              kind={:color}
              open={@avatar_open == :skin}
            />
            <.avatar_dropdown
              field="hair_style"
              label="Hair Length"
              options={Avatar.hair_styles()}
              selected={@avatar.hair_style}
              kind={:text}
              open={@avatar_open == :hair_style}
            />
            <.avatar_dropdown
              field="hair_color"
              label="Hair Color"
              options={Avatar.hair_colors()}
              selected={@avatar.hair_color}
              kind={:swatch_named}
              open={@avatar_open == :hair_color}
            />
            <.avatar_dropdown
              field="accent"
              label="Background Color"
              options={Avatar.accents()}
              selected={@avatar.accent}
              kind={:color}
              open={@avatar_open == :accent}
            />
            <div class="avatar-dropdown">
              <label class="avatar-row-label" for="inspector-name">Inspector Name</label>
              <input
                class="ready-input"
                type="text"
                id="inspector-name"
                name="name"
                placeholder="e.g. Inspector Wazowski"
                value=""
                autocomplete="off"
              />
            </div>
          </div>

          <button class="btn-ready">
            Join
          </button>
        </.form>
      <% end %>
    </div>
    """
  end

  attr :rule_descriptions, :list, required: true
  attr :rules_hidden, :boolean, default: false
  attr :blackout_remaining, :integer, default: 0

  def postal_regulations(assigns) do
    ~H"""
    <div class="rules-reference">
      <div class="rules-header">
        <span class="rules-title">Postal Regulations</span>
      </div>

      <%= if @rules_hidden do %>
        <div style="padding: 40px 20px; text-align: center; color: var(--stamp-red); animation: pulse 1s infinite;">
          <span style="font-size: 48px;">⚠️</span>
          <h2 style="font-family: 'DM Mono', monospace; font-weight: bold; margin-top: 10px;">SYSTEM LOCKDOWN</h2>
          <p style="font-size: 12px; margin-top: 10px;">SEVERE VIOLATION DETECTED.<br/>CONTRABAND MISHANDLED.</p>
          <p style="font-size: 14px; font-weight: bold; margin-top: 20px;">REGULATIONS SUSPENDED FOR {@blackout_remaining}s</p>
        </div>
      <% else %>
        <%= for {desc, index} <- Enum.with_index(@rule_descriptions) do %>
          <div class="rules-list">
            <div class="rule-item">
              <span class="rule-number">{index + 1}</span><span>{desc}</span>
            </div>
          </div>
        <% end %>
      <% end %>
    </div>
    """
  end

  attr :player_list, :list, required: true

  def leaderboard(assigns) do
    ~H"""
    <div class="leaderboard">
      <div class="leaderboard-header">
        <div class="leaderboard-title">Inspector Rankings</div>
      </div>

      <ul class="leaderboard-list">
        <li :for={player <- @player_list} class="leaderboard-item">
          <span class="rank rank-1">1</span>
          <.avatar config={player.avatar} size={28} />
          <div class="lb-player-info">
            <div class="lb-player-name">{player.name}</div>
          </div>
          <div class="lb-player-score">{player.score}</div>
        </li>
      </ul>
    </div>
    """
  end

  attr :player_list, :list, required: true

  def match_end_overlay(assigns) do
    ~H"""
    <div class="match-end-overlay" style="display:flex">
      <div class="match-end-card">
        <div class="match-end-label">Match Complete</div>
        <div class="match-end-title">Final Results</div>
        <ul class="match-end-scores">
          <li :for={{player, index} <- Enum.with_index(@player_list)}>
            <span class="match-end-player">
              {get_medal(index)} <.avatar config={player.avatar} size={26} /> {player.name}
            </span>
            <span class="final-score">{player.score} pts</span>
          </li>
        </ul>
        <button class="btn-new-match" phx-click="new_match">New Match</button>
      </div>
    </div>
    """
  end

  def capitalise(term) do
    String.capitalize("#{term}")
  end

  def get_medal(place) do
    Enum.at(["🥇", "🥈", "🥉"], place)
  end

  def format_points(delta) when delta >= 0, do: "+#{delta}"
  def format_points(delta), do: "−#{abs(delta)}"
end
