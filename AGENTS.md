# ExQuickbooks Agent Guide

ExQuickbooks is a small Elixir library for the Intuit QuickBooks API. Keep changes focused on a clean library API, not Phoenix or application scaffolding.

## Working rules

- Prefer widely used Hex packages over hand-rolled infrastructure when they reduce risk or complexity.
- Keep the public API small and explicit. Return `{:ok, result}` / `{:error, reason}` for expected failures.
- Use descriptive variable and function names. Avoid aliases unless they materially improve readability.
- Separate HTTP request building, response decoding, and domain mapping into distinct modules or functions.
- Handle QuickBooks rate limits, auth failures, and API errors with typed error values instead of raising.
- Keep modules and functions documented with concise `@moduledoc` and `@doc` entries when they are part of the public surface.

## Library preferences

- HTTP client: prefer `Req` unless there is a clear reason to choose another library.
- JSON: prefer `Jason`.
- Config and option validation: prefer `NimbleOptions` when the surface area grows.
- Testing HTTP behavior: prefer `Bypass` or a behaviour-based mock when it keeps tests isolated and deterministic.
- Documentation: prefer `ExDoc` for public API docs.

## Elixir conventions

- Keep functions small and composable.
- Prefer pure functions for request normalization and response parsing.
- Avoid destructuring in function heads; bind values at the start of the function body when needed.
- Keep tests focused on client behavior, request shape, and response decoding.

## Repository pointers

- Read [README.md](README.md) for the current project description and packaging notes.
- Update the README when the public API changes.
