defmodule Mix.Tasks.Exinertia.Setup do
  @moduledoc """
  Creates a new frontend for Inertia.js.

  This task clones the Inertia.js template and then installs its dependencies.
  As a final note, ensure your tailwind.config.js is updated with the proper content paths.
  """

  use Mix.Task

  @shortdoc "Setup new Inertia frontend"

  # Configuration attributes
  @template_repo "nordbeam/exinertia-templates/templates/react-ts"
  @assets_dir "assets"
  @bun_path "_build/bun"

  @impl true
  def run(_args) do
    with {:ok, _} <- Mix.Task.run("bun.install"),
         bun_path = Path.expand(@bun_path, File.cwd!()),
         :ok <- clone_template(bun_path),
         :ok <- install_dependencies(bun_path) do
      Mix.shell().info("""
      Successfully created frontend assets in #{@assets_dir}.

      As a last step, update your tailwind.config.js to add "./js/**/*.{js,ts,jsx,tsx}".
      """)
    else
      {:error, error} when error |> is_binary() ->
        Mix.shell().warning("""
        Failed to clone frontend template:
        #{error}

        You may need to run manually:
          #{@bun_path} x degit #{@template_repo} #{@assets_dir}
        """)

      {:error, error} ->
        Mix.shell().error("Failed to install bun: #{inspect(error)}")
    end
  end

  defp clone_template(bun_path) do
    case System.cmd(bun_path, ["x", "degit", "--force", @template_repo, @assets_dir]) do
      {_output, 0} ->
        :ok

      {error_output, _exit_code} ->
        {:error, error_output}
    end
  end

  defp install_dependencies(bun_path) do
    case System.cmd(bun_path, ["i"], cd: @assets_dir) do
      {_output, 0} ->
        :ok

      {error_output, _exit_code} ->
        {:error, error_output}
    end
  end
end
