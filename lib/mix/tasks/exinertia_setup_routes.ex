defmodule Mix.Tasks.Exinertia.Setup.Routes.Docs do
  @moduledoc false

  def short_doc do
    "Configures Routes in your Phoenix project."
  end

  def example do
    "mix routes.install"
  end

  def long_doc do
    """
    #{short_doc()}

    This installer automates the basic steps for integrating Routes into your Phoenix project.
    It makes changes similar to the following:

      1. Add a "use Routes" call to your Phoenix router.
      2. Configure Routes in config/config.exs with your router module, along with options to output TypeScript
         definitions and customize the routes path.
      3. [Optional] Remind you to add the Routes.Watcher to your supervision tree in development so that routes
         are automatically regenerated when your router file changes.

    ## Configuration

    1. **Add Routes to your Phoenix Router**:

       In your router file (e.g., `lib/your_app_web/router.ex`), add `use Routes`:

       ```elixir
       defmodule YourAppWeb.Router do
         use Phoenix.Router
         use Routes  # Add this line

         # Your routes...
       end
       ```

    2. **Configure Routes in `config/config.exs`**:

       Specify your router module and optional settings:

       ```elixir
       config :routes,
         router: YourAppWeb.Router,
         typescript: true,         # Enable TypeScript output, defaults to false
         routes_path: "assets/js/routes"     # Optional, defaults to "assets/js"
       ```

    3. **[Optional] Enable live reloading of routes**:

       To automatically regenerate routes when your router file changes during development, add the `Routes.Watcher`
       to your application's supervision tree in `lib/your_app/application.ex`:

       ```elixir
       def start(_type, _args) do
         children = [
           # ... other children
         ]

         # Add the Routes.Watcher in development environment
         children = if Mix.env() == :dev do
           children ++ [{Routes.Watcher, []}]
         else
           children
         end

         opts = [strategy: :one_for_one, name: YourApp.Supervisor]
         Supervisor.start_link(children, opts)
       end
       ```

    ## Example

    ```bash
    #{example()}
    ```
    """
  end
end

if Code.ensure_loaded?(Igniter) do
  defmodule Mix.Tasks.Exinertia.Setup.Routes do
    @shortdoc Mix.Tasks.Exinertia.Setup.Routes.Docs.short_doc()
    @moduledoc Mix.Tasks.Exinertia.Setup.Routes.Docs.long_doc()
    require Igniter.Code.Common

    use Igniter.Mix.Task

    @impl Igniter.Mix.Task
    def info(_argv, _composing_task) do
      %Igniter.Mix.Task.Info{
        group: :routes,
        # No new deps are required here so we can leave adds_deps empty
        adds_deps: [],
        installs: [],
        example: Mix.Tasks.Exinertia.Setup.Routes.Docs.example(),
        only: nil,
        positional: [],
        composes: [],
        schema: [
          force: :boolean,
          yes: :boolean
        ],
        defaults: [],
        aliases: [],
        required: []
      }
    end

    @impl Igniter.Mix.Task
    def igniter(igniter, _argv) do
      igniter
      |> add_bun_and_inertia()
      |> update_router()
      |> update_config()
      |> add_live_reloading()
      |> final_instructions()
    end

    defp add_bun_and_inertia(igniter) do
      igniter
      |> Igniter.Project.Deps.add_dep({:routes, "~> 0.1.0"})
    end

    # 1. Update your Phoenix router file to include "use Routes"
    defp update_router(igniter) do
      Igniter.Project.Module.find_and_update_module!(
        igniter,
        Igniter.Libs.Phoenix.web_module(igniter),
        fn zipper ->
          with {:ok, zipper} <- Igniter.Code.Function.move_to_def(zipper, :router, 0),
               {:ok, zipper} <- Igniter.Code.Common.move_to_do_block(zipper) do
            {:ok, Igniter.Code.Common.add_code(zipper, "use Routes")}
          end
        end
      )
    end

    # 2. Update config/config.exs to add a :routes configuration section.
    defp update_config(igniter) do
      router_module = Igniter.Libs.Phoenix.web_module_name(igniter, "Router")

      igniter
      |> Igniter.Project.Config.configure(
        "config/config.exs",
        :routes,
        [:router],
        {:code, Sourceror.parse_string!(inspect(router_module))}
      )
      |> Igniter.Project.Config.configure(
        "config/config.exs",
        :routes,
        [:typescript],
        {:code, Sourceror.parse_string!("true")}
      )
      |> Igniter.Project.Config.configure(
        "config/config.exs",
        :routes,
        [:routes_path],
        {:code, Sourceror.parse_string!("\"assets/js/routes\"")}
      )
    end

    defp add_live_reloading(igniter) do
      application_module = Igniter.Project.Module.module_name(igniter, "Application")

      igniter
      |> Igniter.Project.Module.find_and_update_module!(
        application_module,
        fn zipper ->
          with {:ok, zipper} <- Igniter.Code.Function.move_to_def(zipper, :start, 2),
               {:ok, zipper} <-
                 Igniter.Code.Common.move_to_pattern(zipper, "children = [__cursor__()]") do
            Igniter.Code.Common.add_code(
              zipper,
              """

              children = if Mix.env() == :dev do
                children ++ [{Routes.Watcher, []}]
              else
                children
              end
              """,
              placement: :after
            )
          else
            _ -> {:ok, zipper}
          end
        end
      )
    end

    # 3. Remind the developer to update their application's supervision tree if they desire live reloading.
    defp final_instructions(igniter) do
      Igniter.add_notice(igniter, """
      Routes installation complete.

      Next steps:
      • Verify that your router file (e.g., lib/#{web_dir(igniter)}/router.ex) now includes:
            use Routes

      • Check that your config/config.exs has been updated with:

            config :routes,
              router: #{inspect(Igniter.Libs.Phoenix.web_module_name(igniter, "Router"))},
              typescript: true,
              routes_path: "assets/js/routes"

      • [Optional] To enable live reloading of routes during development, add the following
          to your application's supervision tree (e.g., in lib/your_app/application.ex):

            children = if Mix.env() == :dev do
               children ++ [{Routes.Watcher, []}]
            end

      Happy routing!
      """)
    end

    defp web_dir(igniter) do
      igniter
      |> Igniter.Libs.Phoenix.web_module()
      |> inspect()
      |> Macro.underscore()
    end
  end
else
  # Fallback if Igniter is not installed
  defmodule Mix.Tasks.Exinertia.Setup.Routes do
    @shortdoc Mix.Tasks.Exinertia.Setup.Routes.Docs.short_doc() <> " | Install `igniter` to use"
    @moduledoc Mix.Tasks.Exinertia.Setup.Routes.Docs.long_doc()

    use Mix.Task

    def run(_argv) do
      Mix.shell().error("""
      The task 'exinertia.setup.routes' requires igniter. Please install igniter and try again.

      For more information, see: https://hexdocs.pm/igniter
      """)

      exit({:shutdown, 1})
    end
  end
end
