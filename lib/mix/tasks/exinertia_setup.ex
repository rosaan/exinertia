defmodule Mix.Tasks.Exinertia.Setup.Docs do
  @moduledoc false

  def short_doc do
    "Creates a new frontend for Inertia.js."
  end

  def example do
    "mix exinertia.setup"
  end

  def long_doc do
    """
    #{short_doc()}

    This task clones the Inertia.js template and then installs its dependencies.
    As a final note, ensure your tailwind.config.js is updated with the proper content paths.

    ## Example

    ```bash
    #{example()}
    ```
    """
  end
end

if Code.ensure_loaded?(Igniter) do
  defmodule Mix.Tasks.Exinertia.Setup do
    @shortdoc Mix.Tasks.Exinertia.Setup.Docs.short_doc()
    @moduledoc Mix.Tasks.Exinertia.Setup.Docs.long_doc()

    use Igniter.Mix.Task

    # Configuration attributes
    @template_repo "nordbeam/exinertia-templates/templates/react-ts"
    @assets_dir "assets"
    @bun_path "_build/bun"

    @impl Igniter.Mix.Task
    def info(_argv, _composing_task) do
      %Igniter.Mix.Task.Info{
        group: :exinertia,
        adds_deps: [],
        installs: [],
        example: Mix.Tasks.Exinertia.Setup.Docs.example(),
        only: nil,
        positional: [],
        composes: [],
        schema: [
          force: :boolean
        ],
        defaults: [],
        aliases: [],
        required: []
      }
    end

    @impl Igniter.Mix.Task
    def igniter(igniter, _argv) do
      with :ok <- Mix.Task.run("bun.install"),
           bun_path <- Path.expand(@bun_path, File.cwd!()),
           :ok <- clone_template(bun_path),
           :ok <- install_dependencies(bun_path) do
        Igniter.add_notice(igniter, """
        Successfully created frontend assets in #{@assets_dir}.

        As a last step, update your tailwind.config.js to add "./js/**/*.{js,ts,jsx,tsx}".
        """)
      else
        {:error, error} when error |> is_binary() ->
          Igniter.add_warning(igniter, """
          Failed to clone frontend template:
          #{error}

          You may need to run manually:
            #{@bun_path} x degit #{@template_repo} #{@assets_dir}
          """)

        {:error, error} ->
          Igniter.add_warning(igniter, "Failed to install bun: #{inspect(error)}")
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
else
  defmodule Mix.Tasks.Exinertia.Setup do
    @shortdoc Mix.Tasks.Exinertia.Setup.Docs.short_doc() <> " | Install `igniter` to use"
    @moduledoc Mix.Tasks.Exinertia.Setup.Docs.long_doc()

    use Mix.Task

    def run(_argv) do
      Mix.shell().error("""
      The task 'exinertia.setup' requires igniter. Please install igniter and try again.

      For more information, see: https://hexdocs.pm/igniter
      """)

      exit({:shutdown, 1})
    end
  end
end
