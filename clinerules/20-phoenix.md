# Phoenix Standards

Architecture:

Contexts
↓

Schemas

↓

Controllers / LiveViews

Never place business logic inside:

- LiveView
- Controllers
- Components

Business logic belongs inside Contexts.

HEEx:

- Small components
- Stateless where possible
- Prefer function components

LiveView:

- Avoid unnecessary assigns.
- Use streams when suitable.
- Keep socket assigns minimal.

Routes:

Prefer REST.

Naming:

Resources should be singular modules and plural routes.

Always generate production-ready Phoenix code.
