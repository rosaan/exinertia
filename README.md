# ExInertia

ExInertia is a toolkit for seamlessly integrating Inertia.js with Phoenix, using Bun for JavaScript and CSS bundling.

## Installation

Add Igniter to your dependencies:

```elixir
def deps do
  [
    {:igniter, "~> 0.5", only: [:dev, :test]}
  ]
end
```

Then run:

```bash
mix deps.get
mix igniter.install exinertia
```

This will set up ExInertia and all necessary dependencies in your Phoenix project.

## After Installation

After installation, you'll need to update your `tailwind.config.js` to include `"./js/**/*.{js,ts,jsx,tsx}"` in the content paths.

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
