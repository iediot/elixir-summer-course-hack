defmodule School.Avatar do
  @moduledoc """
  Configuration and option data for player avatars.

  An avatar config is a small map of indices into the option lists below,
  e.g. `%{skin: 0, hair_style: 1, hair_color: 0, accent: 0}`. The actual SVG
  drawing lives in `SchoolWeb.GameComponents.avatar/1`; this module only owns
  the option data so both the customizer and the renderer agree on what's
  available.
  """

  @skins [
    "#ffe0bd",
    "#f5d4a8",
    "#f1c27d",
    "#e0ac69",
    "#c68642",
    "#a8693c",
    "#8d5524",
    "#5c3a1e"
  ]

  @accents [
    "#2c6fbb",
    "#1f9d8a",
    "#10b981",
    "#7cb342",
    "#f59e0b",
    "#ef6c00",
    "#ef4444",
    "#e11d63",
    "#ec4899",
    "#8b5cf6",
    "#6366f1",
    "#475569"
  ]

  @hair_styles [
    %{style: :none, label: "Bald"},
    %{style: :short, label: "Short"},
    %{style: :buzz, label: "Buzz"},
    %{style: :bun, label: "Bun"},
    %{style: :mohawk, label: "Mohawk"},
    %{style: :long, label: "Long"}
  ]

  @hair_colors [
    %{name: "Black", color: "#1a1a1a"},
    %{name: "Brown", color: "#4a2f1a"},
    %{name: "Auburn", color: "#7a3b1f"},
    %{name: "Blonde", color: "#d4b04a"},
    %{name: "Red", color: "#b5341f"},
    %{name: "Grey", color: "#9aa0a6"},
    %{name: "White", color: "#e8e8e8"}
  ]

  @type t :: %{
          skin: non_neg_integer(),
          hair_style: non_neg_integer(),
          hair_color: non_neg_integer(),
          accent: non_neg_integer()
        }

  @fields [:skin, :hair_style, :hair_color, :accent]

  @spec default() :: t()
  def default, do: %{skin: 0, hair_style: 1, hair_color: 0, accent: 0}

  def skins, do: @skins
  def accents, do: @accents
  def hair_styles, do: @hair_styles
  def hair_colors, do: @hair_colors

  def skin(index), do: Enum.at(@skins, index, hd(@skins))
  def accent(index), do: Enum.at(@accents, index, hd(@accents))
  def hair_style(index), do: Enum.at(@hair_styles, index, hd(@hair_styles))
  def hair_color(index), do: Enum.at(@hair_colors, index, hd(@hair_colors))

  def count(:skin), do: length(@skins)
  def count(:accent), do: length(@accents)
  def count(:hair_style), do: length(@hair_styles)
  def count(:hair_color), do: length(@hair_colors)

  @doc "Set `field` of `config` to `index`, wrapped into the valid range."
  def set(config, field, index) when field in @fields do
    Map.put(config, field, normalize(field, index))
  end

  def set(config, _field, _index), do: config

  defp normalize(field, index) do
    c = count(field)
    rem(rem(index, c) + c, c)
  end
end
