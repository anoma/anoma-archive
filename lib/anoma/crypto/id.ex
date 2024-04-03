defmodule Anoma.Crypto.Id do
  @moduledoc """
  I represent the Identity
  """
  use TypedStruct
  alias Anoma.Crypto.{Sign, Encrypt, Symmetric}
  alias Anoma.Crypto.Id.{Intern, Extern}

  @type identities() :: Intern.t() | Extern.t() | t()

  typedstruct do
    field(:internal, Intern.t())
    field(:external, Extern.t())
    field(:kind_sign, atom(), default: :ed25519)
    field(:kind_encrypt, atom(), default: :box)
  end

  typedstruct module: Intern do
    field(:sign, Sign.secret())
    field(:encrypt, Encrypt.secret())
  end

  typedstruct module: Extern do
    field(:sign, Sign.public())
    field(:encrypt, Encrypt.public())
  end

  @spec new_keypair() :: t()
  def new_keypair() do
    %{public: spub, secret: ssec} = Sign.new_keypair()
    %{public: epub, secret: esec} = Encrypt.new_keypair()
    extern = %Extern{sign: spub, encrypt: epub}
    intern = %Intern{sign: ssec, encrypt: esec}
    %__MODULE__{external: extern, internal: intern}
  end

  @spec seal(any(), Extern.t()) :: binary()
  def seal(message, %Extern{encrypt: encrypt}) do
    Encrypt.seal(message, encrypt)
  end

  @spec verify(binary(), Extern.t()) ::
          {:error, :failed_verification} | {:ok, binary()}
  def verify(message, %Extern{sign: sign}) do
    Sign.verify(message, sign)
  end

  @doc """
  I salt the given keys for storage further storage. Or for storage
  lookup

  I can be used on `t\0`, `Intern.t\0` or `Extern.t\0`.

  - `t\0` is useful for salting for storage
  - `Extern.t\0` is useful for looking up keys for storage
  - `Intern.t\0` is useful in case one wants to see the salted key
  """
  @spec salt_keys(identities(), Symmetric.t()) :: identities()
  def salt_keys(id, sym) do
    on_keys(id, fn key -> Symmetric.encrypt_raw(key, sym) end)
  end

  @doc """

  I unsalt the given keys for use after looking up from storage

  I can be used on `t\0`, `Intern.t\0` or `Extern.t\0`.

  - `t\0` is useful for unsalting from Storage
  - `Extern.t\0` is useful for external keys which are salted
  - `Intern.t\0` is useful in case when one wants to unsalt their private keys
  """
  @spec unsalt_keys(identities(), Symmetric.t()) :: identities()
  def unsalt_keys(id, sym) do
    on_keys(id, fn key -> Symmetric.decrypt_raw(key, sym) end)
  end

  @spec on_keys(identities(), (binary() -> binary())) :: identities()
  defp on_keys(mod = %__MODULE__{internal: intern, external: extern}, fun) do
    %__MODULE__{
      mod
      | internal: on_keys(intern, fun),
        external: on_keys(extern, fun)
    }
  end

  defp on_keys(%Intern{sign: sign, encrypt: encrypt}, fun) do
    %Intern{sign: fun.(sign), encrypt: fun.(encrypt)}
  end

  defp on_keys(%Extern{sign: sign, encrypt: encrypt}, fun) do
    %Extern{sign: fun.(sign), encrypt: fun.(encrypt)}
  end
end
