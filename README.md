# ExInertia

ExInertia is a toolkit for seamlessly integrating Inertia.js with Phoenix, using Bun for JavaScript and CSS bundling.

## Installation

Add ExInertia to your dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:exinertia, "~> 0.5.0"}
  ]
end
```

## Quick Start

To start using Inertia with your Phoenix project, just run:

```bash
mix exinertia.install
```

### What does `exinertia.install` do?

The installer automates the basic steps for integrating ExInertia into a Phoenix project:

1. Creates a Vite manifest reader in your Web app folder
2. Adds Inertia and Bun to your mix.exs, removes esbuild/tailwind if present
3. Updates config.exs to configure Bun
4. Updates dev.exs watchers to point to Bun and removes esbuild/tailwind watchers
5. Modifies your router and adds an :inertia pipeline + test route
6. Modifies a controller to render an Inertia page
7. Creates an inertia_root.html.heex layout
8. Modifies the existing root.html.heex to reference your Vite manifest
9. Inserts Inertia imports into lib/myapp_web.ex
10. Updates mix aliases for building/deploying assets with Bun
11. Clones the Inertia.js template from nordbeam/exinertia-templates
12. Installs frontend dependencies with Bun

### What does `exinertia.setup` do?

The setup task:

1. Clones the Inertia.js template
2. Sets up the frontend assets in your `assets` directory
3. Installs all necessary frontend dependencies using Bun

## After Installation

After running both commands, you'll need to update your `tailwind.config.js` to include `"./js/**/*.{js,ts,jsx,tsx}"` in the content paths.

## Development

Start your Phoenix server:

```bash
mix phx.server
```

Visit [`localhost:4000/inertia`](http://localhost:4000/inertia) to see your Inertia-powered page.

## Frequently Asked Questions

### Why not include these installers directly in the Phoenix Inertia adapter?

ExInertia makes some opinionated choices that may not suit everyone's needs. For example, we use Bun and Vite for asset bundling instead of the more commonly used esbuild. By keeping these installers separate, users have the flexibility to choose their preferred tooling while still using the core Inertia adapter.

## Learn More

- [Inertia.js Documentation](https://inertiajs.com/)
- [Phoenix Framework Documentation](https://hexdocs.pm/phoenix/overview.html)
- [Bun Documentation](https://bun.sh/docs)

## License

ExInertia is released under the MIT License.
