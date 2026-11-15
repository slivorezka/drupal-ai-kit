---
name: drupal-refactor-to-di
description: Refactor Drupal code from static Drupal:: calls to dependency injection
argument-hint: <file path or code>
---

You are a Drupal 10/11 refactoring expert. Refactor the provided code to use proper dependency injection, replacing all
static service calls (`\Drupal::service()`, `\Drupal::database()`, etc.) with modern DI patterns following PHP 8.3+ and
Drupal 10/11 best practices.

Analyze and refactor the following code or file: $ARGUMENTS

If a file path is provided, read the file and refactor it. If code is provided directly, refactor it in place.

## Refactoring Goals

1. **Remove all static calls**: Eliminate `\Drupal::service()`, `\Drupal::database()`, `\Drupal::config()`,
   `\Drupal::entityTypeManager()`, `\Drupal::currentUser()`, `\Drupal::logger()`, etc.
2. **Add constructor DI**: Inject all dependencies via the constructor with `private readonly` typed properties
3. **Add `create()` method**: For classes instantiated by the container (controllers, forms, plugins)
4. **Add type hints**: Strict typing on all parameters and return types
5. **Add PHPDoc**: Comprehensive documentation
6. **Create/update services.yml**: Service registration if needed

## Static Call → Service Mapping

```
\Drupal::database()           → @database (Connection)
\Drupal::config()             → @config.factory (ConfigFactoryInterface)
\Drupal::configFactory()      → @config.factory (ConfigFactoryInterface)
\Drupal::entityTypeManager()  → @entity_type.manager (EntityTypeManagerInterface)
\Drupal::currentUser()        → @current_user (AccountProxyInterface)
\Drupal::moduleHandler()      → @module_handler (ModuleHandlerInterface)
\Drupal::logger()             → @logger.channel.{module} (LoggerInterface)
\Drupal::state()              → @state (StateInterface)
\Drupal::cache()              → @cache.default (CacheBackendInterface)
\Drupal::httpClient()         → @http_client (ClientInterface)
\Drupal::service('messenger') → @messenger (MessengerInterface)
\Drupal::formBuilder()        → @form_builder (FormBuilderInterface)
```

## Refactoring Patterns

### Pattern: Controller

- Extend `ControllerBase`
- Add constructor with DI
- Add `create()` static method
- Replace all `\Drupal::` calls with `$this->property`

### Pattern: Form

- Extend `FormBase` or `ConfigFormBase`
- Add constructor with DI
- Add `create()` static method

### Pattern: Plugin (Block, etc.)

- Implement `ContainerFactoryPluginInterface`
- Constructor: `(array $configuration, string $plugin_id, mixed $plugin_definition, ...services)`
- Call `parent::__construct($configuration, $plugin_id, $plugin_definition)` first
- Add `create()` with container + plugin params

### Pattern: Service

- Pure constructor DI (no `create()` method needed)
- Register in `*.services.yml`

### Pattern: Procedural Hook → OOP Hook Class

Procedural hooks in `.module` files cannot use constructor injection. Move them to a class in `src/Hook/` with the
`#[Hook]` attribute (Drupal 11.1+ only — on Drupal 10.x keep the procedural hook as a thin wrapper that only fetches a service with
`\Drupal::service()` and delegates to it; static calls are tolerated in `.module` files, never in classes). Classes in `src/Hook/` are registered as autowired services automatically, so
dependencies are injected via the constructor with no `create()` method and no `services.yml` entry.

```php
<?php

declare(strict_types=1);

namespace Drupal\my_module\Hook;

use Drupal\Core\Hook\Attribute\Hook;
use Drupal\my_module\NodeService;
use Drupal\node\NodeInterface;

/**
 * Node hook implementations for my_module.
 */
final class NodeHooks {

  /**
   * Constructor.
   */
  public function __construct(
    private readonly NodeService $nodeService,
  ) {}

  /**
   * Implements hook_ENTITY_TYPE_insert() for nodes.
   */
  #[Hook('node_insert')]
  public function nodeInsert(NodeInterface $node): void {
    $this->nodeService->onNodeInsert($node);
  }

}
```

Delete the procedural function afterward. Use `#[Hook]` classes in the module's `src/Hook/` directory.

## Output Requirements

Generate all of the following:

1. **Refactored PHP File** — Complete file with:

- `declare(strict_types=1);`
- A proper namespace and imports
- Constructor with `private readonly` dependencies
- `create()` method (if applicable)
- All static calls are replaced with `$this->property`
- Comprehensive PHPDoc blocks

2. **Services.yml Entry** — If a new service is created:

```yaml
services:
  {my_module}.{service_name}:
    class: Drupal\{my_module}\Service\{ServiceName}
    arguments:
      - '@dependency1'
      - '@dependency2'
```

3. **Migration Notes** — Steps to integrate:

- Files changed
- Services added
- Tests to update
- Caches to clear

4. **Before/After Summary** — What changed and why

## Validation Checklist

- [ ] All `\Drupal::` static calls are removed from classes
- [ ] All dependencies are injected via constructor
- [ ] All properties are `private readonly`
- [ ] All parameters and return types have type hints
- [ ] PHPDoc blocks are present and accurate
- [ ] `create()` method implemented (for plugins/forms/controllers)
- [ ] Services registered in services.yml
- [ ] No circular dependencies introduced
- [ ] Backward compatibility maintained
- [ ] Code follows Drupal coding standards

