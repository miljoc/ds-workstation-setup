# Elixir Standards

Use idiomatic Elixir.

Always prefer:

- Pattern matching
- Multiple function heads
- Guards
- Pipelines
- Immutable data

Avoid:

- Nested case statements
- Deeply nested if statements
- Large modules
- Side effects

Prefer:

Enum

over

Recursion

unless recursion is significantly clearer.

Document every public module.

Document every public function.

Prefer explicit function names.

Never use process dictionary.

Never create unnecessary GenServers.
