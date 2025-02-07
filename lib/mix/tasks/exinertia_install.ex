defmodule Mix.Tasks.Exinertia.Install.Docs do
  @moduledoc false

  def short_doc do
    "Installs Exinertia and updates your project accordingly."
  end

  def example do
    "mix exinertia.install"
  end

  def long_doc do
    """
    #{short_doc()}

    This installer automates the basic steps for integrating Exinertia into a Phoenix project
    using bun for JavaScript and CSS bundling, removing esbuild/tailwind configs, and adding
    a simple Inertia setup.

    It follows the rough steps:

      1. Create a Vite manifest reader in your Web app folder.
      2. Add Inertia and bun to your mix.exs, remove esbuild/tailwind if present, and run deps.get.
      3. Update config.exs to configure bun.
      4. Update dev.exs watchers to point to bun and remove esbuild/tailwind watchers.
      5. Modify your router and add an :inertia pipeline + a test route.
      6. Modify a controller to render an Inertia page.
      7. Create an inertia_root.html.heex layout.
      8. Modify the existing root.html.heex to reference your new Vite manifest for main.js.
      9. Insert Inertia imports into lib/myapp_web.ex for your controllers/templates.
      10. Update mix aliases for building/deploying assets with bun.
      11. Clone the Inertia.js template from nordbeam/exinertia-templates
      12. Install frontend dependencies with bun
      13. Configure Tailwind content paths for JavaScript files

    ## Example

    ```bash
    #{example()}
    ```
    """
  end
end

if Code.ensure_loaded?(Igniter) do
  defmodule Mix.Tasks.Exinertia.Install do
    @shortdoc Mix.Tasks.Exinertia.Install.Docs.short_doc()
    @moduledoc Mix.Tasks.Exinertia.Install.Docs.long_doc()

    use Igniter.Mix.Task

    @impl Igniter.Mix.Task
    def info(_argv, _composing_task) do
      %Igniter.Mix.Task.Info{
        group: :exinertia,
        # Our primary new deps. Note that we remove esbuild/tailwind in code below.
        adds_deps: [
          {:inertia, "~> 2.1.0"},
          {:bun, "~> 1.4"}
        ],
        # If we wanted to cascade-install from these deps, we would list them under `installs: []`.
        installs: [],
        example: Mix.Tasks.Exinertia.Install.Docs.example(),
        # You can restrict to :dev or :test if desired
        only: nil,
        positional: [],
        composes: [
          "exinertia.setup"
        ],
        # We'll parse --force, --yes from the CLI
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
    def igniter(igniter, argv) do
      yes = "--yes" in argv or "-y" in argv

      igniter
      |> remove_esbuild_and_tailwind()
      |> add_bun_and_inertia()
      |> fetch_and_install_deps(yes)
      |> create_vite_manifest_file()
      |> update_config_for_bun()
      |> update_config_for_inertia()
      |> update_dev_watchers()
      |> update_mix_aliases()
      |> update_router_pipeline()
      |> update_inertia_controller_example()
      |> create_inertia_root_layout()
      |> patch_root_layout()
      |> patch_layouts()
      |> patch_web_module()
      |> Igniter.add_task("exinertia.setup")
      |> final_instructions()
    end

    # 1. Remove esbuild and tailwind from mix.exs, if they exist
    defp remove_esbuild_and_tailwind(igniter) do
      igniter
      |> Igniter.Project.Deps.remove_dep("esbuild")
      |> Igniter.Project.Deps.remove_dep("tailwind")
    end

    defp add_bun_and_inertia(igniter) do
      igniter
      |> Igniter.Project.Deps.add_dep({:inertia, "~> 2.1.0"})
      |> Igniter.Project.Deps.add_dep({:bun, "~> 1.4"})
    end

    # 2. Create the Vite manifest reader file (my_app_web/vite.ex or manifest.ex)
    #    (In the guide, it was recommended to place it in your app_web folder as manifest.ex.)
    #    Below we show how you might do that using Igniter's file generator.
    defp create_vite_manifest_file(igniter) do
      file_path = Path.join(["lib", web_dir(igniter), "manifest.ex"])
      code = vite_manifest_code(igniter)

      Igniter.create_new_file(igniter, file_path, code)
    end

    # 3. Update config.exs to configure bun, removing old esbuild/tailwind configs if present.
    defp update_config_for_bun(igniter) do
      igniter
      |> Igniter.Project.Config.configure(
        "config.exs",
        :bun,
        [:version],
        {:code, Sourceror.parse_string!("\"1.2.1\"")}
      )
      |> Igniter.Project.Config.configure(
        "config.exs",
        :bun,
        [:dev],
        {:code,
         Sourceror.parse_string!("""
         [
           args: ~w(run dev),
           cd: Path.expand("../assets", __DIR__),
           env: %{}
         ]
         """)}
      )
      |> Igniter.Project.Config.configure(
        "config.exs",
        :bun,
        [:build],
        {:code,
         Sourceror.parse_string!("""
         [
           args: ~w(run build),
           cd: Path.expand("../assets", __DIR__),
           env: %{}
         ]
         """)}
      )
      |> Igniter.Project.Config.configure(
        "config.exs",
        :bun,
        [:css],
        {:code,
         Sourceror.parse_string!("""
         [
           args: ~w(run tailwindcss --input=css/app.css --output=../priv/static/assets/app.css),
           cd: Path.expand("../assets", __DIR__),
           env: %{}
         ]
         """)}
      )
    end

    defp update_config_for_inertia(igniter) do
      igniter
      |> Igniter.Project.Config.configure(
        "config.exs",
        :inertia,
        [:endpoint],
        {:code, Sourceror.parse_string!("#{inspect(web_module_name(igniter))}.Endpoint")}
      )
      |> Igniter.Project.Config.configure(
        "config.exs",
        :inertia,
        [:static_paths],
        {:code, Sourceror.parse_string!("[\"/assets/app.js\"]")}
      )
      |> Igniter.Project.Config.configure(
        "config.exs",
        :inertia,
        [:default_version],
        {:code, Sourceror.parse_string!("\"1\"")}
      )
      |> Igniter.Project.Config.configure(
        "config.exs",
        :inertia,
        [:camelize_props],
        {:code, Sourceror.parse_string!("false")}
      )
      |> Igniter.Project.Config.configure(
        "config.exs",
        :inertia,
        [:history],
        {:code, Sourceror.parse_string!("[encrypt: false]")}
      )
      |> Igniter.Project.Config.configure(
        "config.exs",
        :inertia,
        [:ssr],
        {:code, Sourceror.parse_string!("false")}
      )
      |> Igniter.Project.Config.configure(
        "config.exs",
        :inertia,
        [:raise_on_ssr_failure],
        {:code, Sourceror.parse_string!("config_env() != :prod")}
      )
    end

    # 4. Edit dev.exs watchers: add watchers for bun to config :otp_app
    defp update_dev_watchers(igniter) do
      otp_app = otp_app(igniter)

      igniter
      |> Igniter.Project.Config.configure(
        "dev.exs",
        otp_app,
        [Igniter.Libs.Phoenix.web_module_name(igniter, "Endpoint"), :watchers],
        {:code,
         Sourceror.parse_string!("""
         [
           bun: {Bun, :install_and_run, [:dev, ~w()]},
           bun_css: {Bun, :install_and_run, [:css, ~w(--watch)]}
         ]
         """)}
      )
    end

    # 5. Edit mix.exs to add new asset aliases for bun usage:
    defp update_mix_aliases(igniter) do
      igniter
      |> Igniter.Project.TaskAliases.modify_existing_alias("assets.setup", fn zipper ->
        {:ok, Sourceror.Zipper.replace(zipper, quote(do: ["bun.install"]))}
      end)
      |> Igniter.Project.TaskAliases.modify_existing_alias("assets.build", fn zipper ->
        {:ok, Sourceror.Zipper.replace(zipper, quote(do: ["bun build", "bun css"]))}
      end)
      |> Igniter.Project.TaskAliases.modify_existing_alias("assets.deploy", fn zipper ->
        {:ok,
         Sourceror.Zipper.replace(
           zipper,
           quote(do: ["bun build --minify", "bun css --minify", "phx.digest"])
         )}
      end)
    end

    # 6. Add "pipeline :inertia" to router plus a small example route:
    defp update_router_pipeline(igniter) do
      inertia_pipeline = """
        plug :accepts, ["html"]
        plug :fetch_session
        plug :fetch_live_flash
        plug :put_root_layout, html: {#{inspect(web_module_name(igniter))}.Layouts, :inertia_root}
        plug :protect_from_forgery
        plug :put_secure_browser_headers
        plug Inertia.Plug
      """

      igniter
      |> Igniter.Libs.Phoenix.add_pipeline(
        :inertia,
        inertia_pipeline,
        arg2: web_module_name(igniter)
      )
      |> Igniter.Libs.Phoenix.add_scope(
        "/inertia",
        """
        pipe_through :inertia
        get "/", PageController, :inertia
        """,
        arg2: web_module_name(igniter)
      )
    end

    # 7. Update a controller (PageController) with an inertia action. We'll do a naive insertion:
    defp update_inertia_controller_example(igniter) do
      Igniter.Project.Module.find_and_update_module!(
        igniter,
        Igniter.Libs.Phoenix.web_module_name(igniter, "PageController"),
        fn zipper ->
          inertia_fn = """
          def inertia(conn, _params) do
            conn
            |> render_inertia("Dashboard")
          end
          """

          {:ok, Igniter.Code.Common.add_code(zipper, inertia_fn)}
        end
      )
    end

    # 8. Create an inertia_root.html.heex in MyAppWeb.Components.Layouts
    defp create_inertia_root_layout(igniter) do
      file_path =
        Path.join([
          "lib",
          web_dir(igniter),
          "components",
          "layouts",
          "inertia_root.html.heex"
        ])

      content = inertia_root_html()

      Igniter.create_new_file(igniter, file_path, content)
    end

    # 9. Patch the existing root.html.heex to reference your Vite manifest for main_js
    defp patch_root_layout(igniter) do
      file_path =
        Path.join([
          "lib",
          web_dir(igniter),
          "components",
          "layouts",
          "root.html.heex"
        ])

      script_snippet = """
      <%= if dev_env?() do %>
        <script type="module" src="http://localhost:5173/js/app.js">
        </script>
      <% else %>
        <script type="module" crossorigin defer phx-track-static src={Vite.Manifest.main_js()}>
        </script>
      <% end %>
      """

      updater = fn source ->
        source
        |> Rewrite.Source.update(:content, fn content ->
          content
          |> String.replace(~r/<script[^>]*>.*?<\/script>/s, "")
          |> String.replace("</head>", "#{script_snippet}\n  </head>")
        end)
      end

      Igniter.update_file(igniter, file_path, updater)
    end

    defp patch_layouts(igniter) do
      Igniter.Project.Module.find_and_update_module!(
        igniter,
        Igniter.Libs.Phoenix.web_module_name(igniter, "Layouts"),
        fn zipper ->
          {:ok,
           Igniter.Code.Common.add_code(zipper, """
             def dev_env? do
              Mix.env() == :dev
             end
           """)}
        end
      )
    end

    # 10. Patch lib/myapp_web.ex to import Inertia.Controller and Inertia.HTML in the relevant blocks
    defp patch_web_module(igniter) do
      igniter =
        Igniter.Project.Module.find_and_update_module!(
          igniter,
          web_module_name(igniter),
          fn zipper ->
            with {:ok, zipper} <- Igniter.Code.Function.move_to_def(zipper, :controller, 0),
                 {:ok, zipper} <- Igniter.Code.Common.move_to_do_block(zipper) do
              {:ok, Igniter.Code.Common.add_code(zipper, "import Inertia.Controller")}
            end
          end
        )

      Igniter.Project.Module.find_and_update_module!(
        igniter,
        web_module_name(igniter),
        fn zipper ->
          with {:ok, zipper} <- Igniter.Code.Function.move_to_def(zipper, :html, 0),
               {:ok, zipper} <- Igniter.Code.Common.move_to_do_block(zipper) do
            {:ok, Igniter.Code.Common.add_code(zipper, "import Inertia.HTML")}
          end
        end
      )
    end

    # After applying most of our changes, run "mix deps.get" and then "mix bun.install"
    defp fetch_and_install_deps(igniter, yes) do
      Igniter.apply_and_fetch_dependencies(igniter, yes: yes, yes_to_deps: true)
    end

    # Finally, we can print instructions or reminders
    defp final_instructions(igniter) do
      Igniter.add_notice(igniter, """
      Exinertia installation complete.

      Next steps:
      • Update tailwind.config.js to include "./js/**/*.{js,ts,jsx,tsx}" in content paths
      • Run "mix exinertia.setup.routes" to add the Routes library to the project (optional)

      Happy coding with Inertia and Phoenix!
      """)
    end

    #
    # Helper functions
    #

    # Return the code for the Vite manifest module, adapted from your example
    defp vite_manifest_code(igniter) do
      """
      defmodule Vite do
        @moduledoc false

        # Provide "constants" as functions so that inner modules can refer to them.
        def manifest_file, do: "priv/static/assets/vite_manifest.json"
        def cache_key, do: {:vite, "vite_manifest"}
        def default_env, do: :dev
        def endpoint, do: #{inspect(web_module_name(igniter))}.Endpoint

        defmodule PhxManifestReader do
          @moduledoc \"\"\"
          Reads Vite manifest data either from a built digest (for prod) or directly from disk (for non-prod).
          \"\"\"
          require Logger
          alias Vite

          @spec read() :: map()
          def read do
            case :persistent_term.get(Vite.cache_key(), nil) do
              nil ->
                manifest = do_read(current_env())
                :persistent_term.put(Vite.cache_key(), manifest)
                manifest

              manifest ->
                manifest
            end
          end

          @spec current_env() :: atom()
          def current_env do
            Application.get_env(:#{otp_app(igniter)}, :env, Vite.default_env())
          end

          @spec do_read(atom()) :: map()
          defp do_read(:prod), do: read_prod_manifest()
          defp do_read(_env), do: read_file_manifest(Vite.manifest_file())

          # Reads the manifest file from the built static digest in production.
          @spec read_prod_manifest() :: map()
          defp read_prod_manifest do
            # In production the manifest location is picked up from the parent's manifest_file/0.

            {otp_app, relative_path} = {Vite.endpoint().config(:otp_app), Vite.manifest_file()}

            manifest_path = Application.app_dir(otp_app, relative_path)

            with true <- File.exists?(manifest_path),
                 {:ok, content} <- File.read(manifest_path),
                 {:ok, decoded} <- Phoenix.json_library().decode(content) do
              decoded
            else
              _ ->
                Logger.error(
                  "Could not find static manifest at \#{inspect(manifest_path)}. " <>
                    "Run \\"mix phx.digest\\" after building your static files " <>
                    "or remove the configuration from \\"config/prod.exs\\"."
                )
                %{}
            end
          end

          # Reads the manifest from a file for non-production environments.
          @spec read_file_manifest(String.t()) :: map()
          defp read_file_manifest(path) do
            path
            |> File.read!()
            |> Jason.decode!()
          end
        end

        defmodule Manifest do
          @moduledoc \"\"\"
          Retrieves Vite's generated file references.
          \"\"\"
          alias Vite.PhxManifestReader

          @main_js_file "js/app.js"
          @inertia_js_file "js/inertia.tsx"

          @spec read() :: map()
          def read, do: PhxManifestReader.read()

          @doc "Returns the main JavaScript file path prepended with a slash."
          @spec main_js() :: String.t()
          def main_js, do: get_file(@main_js_file)

          @doc "Returns the inertia JavaScript file path prepended with a slash."
          @spec inertia_js() :: String.t()
          def inertia_js, do: get_file(@inertia_js_file)

          @doc "Returns the main CSS file path prepended with a slash, if available."
          @spec main_css() :: String.t()
          def main_css, do: get_css(@main_js_file)

          @spec get_file(String.t()) :: String.t()
          def get_file(file) do
            read()
            |> get_in([file, "file"])
            |> prepend_slash()
          end

          @spec get_css(String.t()) :: String.t()
          def get_css(file) do
            read()
            |> get_in([file, "css"])
            |> List.first()
            |> prepend_slash()
          end

          @doc \"\"\"
          Returns the list of import paths for a given file,
          each path is prepended with a slash.
          \"\"\"
          @spec get_imports(String.t()) :: [String.t()]
          def get_imports(file) do
            read()
            |> get_in([file, "imports"])
            |> case do
              nil -> []
              imports -> Enum.map(imports, &get_file/1)
            end
          end

          defp prepend_slash(nil), do: ""
          defp prepend_slash(path) when is_binary(path), do: "/" <> path
          defp prepend_slash(_), do: ""
        end
      end
      """
    end

    # The inertia_root.html.heex layout content
    defp inertia_root_html do
      """
      <!DOCTYPE html>
      <html lang="en" class="[scrollbar-gutter:stable]">
        <head>
          <meta charset="utf-8" />
          <meta name="viewport" content="width=device-width, initial-scale=1" />
          <meta name="csrf-token" content={get_csrf_token()} />
          <.inertia_title><%= assigns[:page_title] %></.inertia_title>
          <.inertia_head content={@inertia_head} />
          <link phx-track-static rel="stylesheet" href={~p"/assets/app.css"} />
          <%= if dev_env?() do %>
            <script type="module">
              import RefreshRuntime from 'http://localhost:5173/@react-refresh'
              RefreshRuntime.injectIntoGlobalHook(window)
              window.$RefreshReg$ = () => {}
              window.$RefreshSig$ = () => (type) => type
              window.__vite_plugin_react_preamble_installed__ = true
            </script>
            <script type="module" src="http://localhost:5173/@vite/client"></script>
            <script type="module" src="http://localhost:5173/js/inertia.tsx"></script>
          <% else %>
            <script type="module" crossorigin defer phx-track-static src={Vite.Manifest.inertia_js()}>
            </script>
          <% end %>
        </head>
        <body class="bg-white">
          <%= @inner_content %>
        </body>
      </html>
      """
    end

    # Helpers to get the OTP and Web module names from the project:
    defp otp_app(igniter) do
      Igniter.Project.Application.app_name(igniter)
    end

    defp web_module_name(igniter) do
      Igniter.Libs.Phoenix.web_module(igniter)
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
  defmodule Mix.Tasks.Exinertia.Install do
    @shortdoc Mix.Tasks.Exinertia.Install.Docs.short_doc() <> " | Install `igniter` to use"
    @moduledoc Mix.Tasks.Exinertia.Install.Docs.long_doc()

    use Mix.Task

    def run(_argv) do
      Mix.shell().error("""
      The task 'exinertia.install' requires igniter. Please install igniter and try again.

      For more information, see: https://hexdocs.pm/igniter
      """)

      exit({:shutdown, 1})
    end
  end
end
