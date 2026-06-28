defmodule School.Player do
  @type t :: %__MODULE__{
          name: String.t(),
          score: integer(),
          pid: pid(),
          ready?: boolean(),
          avatar: School.Avatar.t()
        }

  defstruct name: nil,
            score: 0,
            pid: nil,
            ready?: false,
            avatar: %{skin: 0, hair_style: 1, hair_color: 0, accent: 0}
end
