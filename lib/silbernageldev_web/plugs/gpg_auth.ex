defmodule GPGAuth do
  @behaviour Plug

  import Plug.Conn
  alias Phoenix.Controller

  @impl true
  def init(module: module), do: module
  def init(_), do: raise("module is a required option and the only option")

  @impl true
  def call(%{method: method} = conn, module) do
    case validate_method(method) do
      "invalid" -> invalid_method(conn)
      "get" -> generate_challenge(conn, module)
      "post" -> validate_challenge(conn, module)
    end

    # Determine if this is the first leg of the request or second

    # IF FIRST
    # Find the public key from the fingerprint of the request
    #    - the public key may be in the DB
    #    - the public key may just be on the filesystem
    # Encrypt a challenge with the public key and store the challenge
    # Send a response with the encrypted challenge

    # IF SECOND
    # Validaate the signnature of the body
    # Check that the unencrypted value matches the challenge
    # Generate a valid token
    # Respond with token
    # Optionally store token in a sessions table
  end

  defp invalid_method(conn), do: send_resp(conn, 406, "Invalid Request")

  defp generate_challenge(%{params: %{"email" => ""}} = conn, _module),
    do: send_resp(conn, 406, "Invalid Request")

  defp generate_challenge(%{params: %{"email" => email}} = conn, module) do
    user = apply(module, :find_user, [email])

    case find_or_import_key(user) do
      :ok ->
        create_and_save_challenge(conn, user, module)

      {:error, _reason} ->
        send_resp(conn, 406, "Invalid Request")
    end
  end

  defp generate_challenge(%{params: _params} = conn, _module),
    do: send_resp(conn, 406, "Invalid Request")

  defp validate_challenge(
         %{params: %{"id" => id, "challenge_response" => challenge}} = conn,
         _module
       ) do
    send_resp(conn, 200, "NICE WORK")
  end

  defp validate_challenge(%{params: _params} = conn, _module) do
    send_resp(conn, 406, "Invalid Request")
  end


  defp create_and_save_challenge(conn, %{email: email} = user, module) do
    dice = Diceware.generate()

    case GPG.encrypt(email, dice.phrase) do
      {:ok, challenge} ->
        # @TODO: add an expiration
        apply(module, :store_challenge_for, [user, challenge])

        conn
        |> put_status(201)
        |> Controller.json(%{challenge: challenge, id: user.id})

      {:error, _} ->
        send_resp(conn, 406, "Invalid Request")
    end
  end

  defp find_or_import_key(nil), do: {:error, :invalid_email}

  defp find_or_import_key(%{email: email}) do
    case GPG.get_public_key(email) do
      {:ok, _fingerprint} ->
        :ok

      {:error, _} ->
        try_import(email)
    end
  end

  defp try_import(email) do
    # try to import it via WKS
    case import_via_wkd(email) do
      {_, 0} -> :ok
      {_, _} -> import_via_openpgp(email)
    end
  end

  defp import_via_wkd(email) do
    System.cmd("gpg", [
      "--locate-keys",
      "--auto-key-locate",
      "clear,nodefault,wkd",
      email
    ])
  end

  defp import_via_openpgp(_email) do
    {:error, :not_implemented}
  end

  defp validate_method(method) do
    case String.downcase(method) do
      m when m in ["get", "post"] -> m
      _other -> "invalid"
    end
  end

  @type user :: %{id: any(), email: binary()}
  @callback find_user(String.t()) :: user()

  @type challenge() :: binary()
  @callback store_challenge_for(user(), challenge()) :: :ok | {:error, binary()}

  defmacro __using__(_) do
    quote location: :keep do
      require unquote(__MODULE__)
      @behaviour GPGAuth
    end
  end
end
