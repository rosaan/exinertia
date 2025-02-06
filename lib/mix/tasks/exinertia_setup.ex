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
  @bun_path Path.expand("./_build/bun")

  @impl true
  def run(_args) do
    case clone_template() do
      :ok ->
        case install_dependencies() do
          :ok ->
            Mix.shell().info("""
            Successfully created frontend assets in #{@assets_dir}.

            As a last step, update your tailwind.config.js to add "./js/**/*.{js,ts,jsx,tsx}".
            """)

          {:error, msg} ->
            Mix.shell().warning("""
            Successfully set up frontend assets but failed to install dependencies:
            #{msg}

            You may need to run manually:
              cd #{@assets_dir} && #{@bun_path} i
            """)
        end

      {:error, msg} ->
        Mix.shell().warning("""
        Failed to clone frontend template:
        #{msg}

        You may need to run manually:
          #{@bun_path} x degit #{@template_repo} #{@assets_dir}
        """)
    end
  end

  defp clone_template do
    case System.cmd(@bun_path, ["x", "degit", "--force", @template_repo, @assets_dir]) do
      {_output, 0} ->
        :ok

      {error_output, _exit_code} ->
        {:error, error_output}
    end
  end

  defp install_dependencies do
    case System.cmd(@bun_path, ["i"], cd: @assets_dir) do
      {_output, 0} ->
        :ok

      {error_output, _exit_code} ->
        {:error, error_output}
    end
  end
end
