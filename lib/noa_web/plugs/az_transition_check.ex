defmodule NoaWeb.Plugs.AzTransitionCheck do
  @moduledoc false

  import Plug.Conn

  def init(opts) when is_list(opts) do
    with  stage when stage in ["consent", "auth"] <- opts[:stage],
          methods = opts[:methods] || ["GET"]
    do
      %{stage: stage, methods: methods}
    else
      _ -> raise "AzTransitionCheck: Invalid options"
    end
  end

  def call(%{method: m} = conn, %{stage: expected_stage, methods: methods}) do
    if m in methods do
      session_stage  = conn |> get_session("x-noa-az-stage")
      session_state  = conn |> get_session("x-noa-az-state-" <> expected_stage)
      params_state   = conn.params |> Map.get("state")
      with  :ok <- valid_stage?(session_stage, expected_stage),
            :ok <- state_match?(session_state, params_state)
      do
        conn
      else
        {:error, reason} -> halt_request(conn, Atom.to_string(reason))
      end
    else
      conn
    end
  end

  defp valid_stage?(session_stage, expected_stage) when session_stage == expected_stage, do: :ok
  defp valid_stage?(_, _), do: {:error, :invalid_stage}

  defp state_match?(state1, state2) when (state1 == state2) and state1 != nil, do: :ok
  defp state_match?(_, _), do: {:error, :mismatched_state}

  defp halt_request(conn, reason) do
    msg = ~s({"error": "forbidden", "error_description": #{inspect reason}})
    conn
    |>  put_resp_header("content-type", "application/json")
    |>  send_resp(403, msg)
    |>  halt()
  end
end
