defmodule Noa.ROProvider do
  @moduledoc false

  @callback get_by_creds(username :: binary, passwd :: binary) ::
      {:ok, map} | {:error, any}
end
