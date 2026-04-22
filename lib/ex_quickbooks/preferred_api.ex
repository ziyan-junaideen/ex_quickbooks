defmodule ExQuickbooks.PreferredAPI do
  @moduledoc false

  @spec legacy_client(ExQuickBooks.Client.t() | ExQuickbooks.Client.t()) ::
          ExQuickbooks.Client.t()
  def legacy_client(%ExQuickBooks.Client{} = client) do
    ExQuickBooks.Client.to_legacy(client)
  end

  def legacy_client(%ExQuickbooks.Client{} = client) do
    client
  end

  @spec legacy_request(ExQuickBooks.Request.t() | ExQuickbooks.Request.t()) ::
          ExQuickbooks.Request.t()
  def legacy_request(%ExQuickBooks.Request{} = request) do
    ExQuickBooks.Request.to_legacy(request)
  end

  def legacy_request(%ExQuickbooks.Request{} = request) do
    request
  end

  @spec new_result({:ok, term()} | {:error, ExQuickbooks.Error.t()}) ::
          {:ok, term()} | {:error, ExQuickBooks.Error.t()}
  def new_result({:ok, value}) do
    {:ok, value}
  end

  def new_result({:error, %ExQuickbooks.Error{} = error}) do
    {:error, ExQuickBooks.Error.from_legacy(error)}
  end

  @spec new_client_result({:ok, ExQuickbooks.Client.t()} | {:error, ExQuickbooks.Error.t()}) ::
          {:ok, ExQuickBooks.Client.t()} | {:error, ExQuickBooks.Error.t()}
  def new_client_result({:ok, %ExQuickbooks.Client{} = client}) do
    {:ok, ExQuickBooks.Client.from_legacy(client)}
  end

  def new_client_result({:error, %ExQuickbooks.Error{} = error}) do
    {:error, ExQuickBooks.Error.from_legacy(error)}
  end

  @spec new_token_result({:ok, ExQuickbooks.Token.t()} | {:error, ExQuickbooks.Error.t()}) ::
          {:ok, ExQuickBooks.Token.t()} | {:error, ExQuickBooks.Error.t()}
  def new_token_result({:ok, %ExQuickbooks.Token{} = token}) do
    {:ok, ExQuickBooks.Token.from_legacy(token)}
  end

  def new_token_result({:error, %ExQuickbooks.Error{} = error}) do
    {:error, ExQuickBooks.Error.from_legacy(error)}
  end
end
