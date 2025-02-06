# ExInertia

ExInertia is a toolkit for seamlessly integrating Inertia.js with Phoenix, using Bun for JavaScript and CSS bundling.

## Installation

Add ExInertia to your dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:exinertia, "~> 0.1.0"}
  ]
end
```

## Quick Start

ExInertia provides two main mix tasks to get you up and running:

1. Install ExInertia and configure your project:
```bash
mix exinertia.install
```

2. Install dependencies and Bun:
```bash
mix deps.get
mix bun.install
```

3. Scaffold the Inertia frontend:
```bash
mix exinertia.setup
```

### What does `exinertia.install` do?

The installer automates the basic steps for integrating ExInertia into a Phoenix project:

1. Creates a Vite manifest reader in your Web app folder
2. Adds Inertia and Bun to your mix.exs
3. Updates config.exs to configure Bun
4. Updates dev.exs watchers to point to Bun
5. Modifies your router and adds an :inertia pipeline + test route
6. Modifies a controller to render an Inertia page
7. Creates an inertia_root.html.heex layout
8. Modifies the existing root.html.heex to reference your Vite manifest
9. Inserts Inertia imports into lib/myapp_web.ex
10. Updates mix aliases for building/deploying assets with Bun

### What does `exinertia.setup` do?

The setup task:

1. Clones a React TypeScript template for Inertia.js
2. Sets up the frontend assets in your `assets` directory
3. Installs all necessary frontend dependencies using Bun

## After Installation

After running both commands, you'll need to:

1. Run `mix deps.get` to install new dependencies
2. Run `mix bun.install` to install Bun and dependencies
3. Update your `tailwind.config.js` to include `"./js/**/*.{js,ts,jsx,tsx}"` in the content paths

## Development

Start your Phoenix server:

```bash
mix phx.server
```

Visit [`localhost:4000/inertia`](http://localhost:4000/inertia) to see your Inertia-powered page.

## Learn More

- [Inertia.js Documentation](https://inertiajs.com/)
- [Phoenix Framework Documentation](https://hexdocs.pm/phoenix/overview.html)
- [Bun Documentation](https://bun.sh/docs)

## License

ExInertia is released under the MIT License.
