defmodule Anoma.ShieldedResource.ProofRecord do
  @moduledoc """
  I am a proof record for a shielded resource.
  """

  alias __MODULE__
  use TypedStruct

  @behaviour Noun.Nounable.Kind

  typedstruct enforce: true do
    field(:proof, binary(), default: <<>>)
    field(:public_inputs, binary(), default: <<>>)
  end

  @spec from_noun(Noun.t()) :: {:ok, t()} | :error
  def from_noun([proof | public_inputs]) do
    {:ok,
     %ProofRecord{
       proof: proof,
       public_inputs: public_inputs
     }}
  end

  def from_noun(_), do: :error

  defimpl Noun.Nounable, for: __MODULE__ do
    def to_noun(proof_record = %ProofRecord{}) do
      {
        proof_record.proof,
        proof_record.public_inputs
      }
      |> Noun.Nounable.to_noun()
    end
  end

  @spec generate_proof(binary(), binary()) :: {:ok, t()} | :error
  def generate_proof(circuit, inputs) do
    {_output, trace, memory, public_inputs} =
      Cairo.cairo_vm_runner(
        circuit,
        inputs
      )

    {proof, public_inputs} = Cairo.prove(trace, memory, public_inputs)

    {:ok,
     %ProofRecord{
       proof: proof |> :binary.list_to_bin(),
       public_inputs: public_inputs |> :binary.list_to_bin()
     }}
  end

  @spec generate_compliance_proof(binary()) :: {:ok, t()} | :error
  def generate_compliance_proof(compliance_inputs) do
    with {:ok, compliance_circuit} <-
           File.read("./params/cairo_compliance.json") do
      generate_proof(compliance_circuit, compliance_inputs)
    else
      _ -> :error
    end
  end
end
