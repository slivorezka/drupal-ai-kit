---
name: drupal-refactor-to-di
description: "Refactor Drupal code from static \\Drupal:: calls to dependency injection"
argument-hint: <file or directory>
---

Refactor this code to dependency injection: $ARGUMENTS

The target rules are in `.ai-kit/instructions/drupal.md` §3 and §5 and `.ai-kit/instructions/php.md` §5; read them
first. This skill is the procedure.

## Steps

1. **List the static calls.** `grep -n '\\Drupal::' <target>` — every hit inside a class is in scope. Hits in
   `.module`, `.install` and `.theme` files are handled by the "Procedural code" branch below.

2. **Map each call to a service and an interface.**

   | Static call                            | Service                   | Type-hint                    |
   |----------------------------------------|---------------------------|------------------------------|
   | `\Drupal::database()`                  | `database`                | `Connection`                 |
   | `\Drupal::config()`, `configFactory()` | `config.factory`          | `ConfigFactoryInterface`     |
   | `\Drupal::entityTypeManager()`         | `entity_type.manager`     | `EntityTypeManagerInterface` |
   | `\Drupal::currentUser()`               | `current_user`            | `AccountProxyInterface`      |
   | `\Drupal::moduleHandler()`             | `module_handler`          | `ModuleHandlerInterface`     |
   | `\Drupal::logger('x')`                 | `logger.channel.<module>` | `LoggerInterface`            |
   | `\Drupal::state()`                     | `state`                   | `StateInterface`             |
   | `\Drupal::cache()`                     | `cache.default`           | `CacheBackendInterface`      |
   | `\Drupal::httpClient()`                | `http_client`             | `ClientInterface`            |
   | `\Drupal::messenger()`                 | `messenger`               | `MessengerInterface`         |
   | `\Drupal::formBuilder()`               | `form_builder`            | `FormBuilderInterface`       |
   | `\Drupal::time()`                      | `datetime.time`           | `TimeInterface`              |
   | `\Drupal::languageManager()`           | `language_manager`        | `LanguageManagerInterface`   |
   | `\Drupal::service('x')`                | `x`                       | the interface of `x`         |

3. **Inject by class kind.**

   - **Service** — promoted `private readonly` constructor parameters; registered by class name with
     `autowire: true`. Update the existing `services.yml` entry instead of adding a second one. A logger channel or
     a cache bin is not identified by its type: name the service on the parameter with
     `#[Autowire(service: 'logger.channel.<module>')]` (`drupal.md` §5, §12, §13).
   - **Controller, form** — constructor plus static `create(ContainerInterface $container): self`.
   - **Plugin** — implement `ContainerFactoryPluginInterface`; the constructor takes the base class's constructor
     arguments followed by the services and calls `parent::__construct()` first; static `create()` receives the
     container and the same base arguments.
   - **Hook class in `src/Hook/`** — constructor only; these classes are autowired services with no `create()` and
     no `services.yml` entry.

   **Inherited properties.** `ControllerBase`, `FormBase` and `PluginBase` already declare properties such as
   `$entityTypeManager`, `$currentUser`, `$configFactory` and `$messenger`; promoting a constructor parameter with
   the same name is a fatal error. Inject under a name the base class does not use — the list and the rule are in
   `drupal.md` §5, "Inherited properties".

4. **Procedural code** (`.module`, `.install`, `.theme`) has no constructor.
   - Drupal 11.2+: move each hook to a `#[Hook]` method on a class in `src/Hook/` and delete the function.
   - Drupal 11.1: the same, except preprocess hooks, which stay procedural.
   - Theme hooks in `<theme>.theme`: from Drupal 11.3 move them the same way to `#[Hook]` classes in the theme's
     own `src/Hook/`; up to 11.2 they stay functions.
   - Drupal 10.x, the procedural-only hooks on every version (install and update hooks, `hook_hook_info()`,
     `hook_module_implements_alter()` — `drupal.md` §3), and theme functions up to 11.2: keep the function as a
     thin wrapper that fetches one service with `\Drupal::service()` and delegates to it. Static calls are accepted
     there and nowhere else.

   ```php
   <?php

   declare(strict_types=1);

   namespace Drupal\my_module\Hook;

   use Drupal\Core\Hook\Attribute\Hook;
   use Drupal\my_module\Service\NodeService;
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

5. **Update the tests** of every changed class: constructor arguments changed, so mocks must be passed in.

6. **Verify.**

   ```bash
   grep -n '\\Drupal::' <changed class files>      # expect no output
   ddev drush cr
   ddev exec vendor/bin/phpcs --standard=Drupal,DrupalPractice <changed files>
   ddev exec vendor/bin/phpunit <tests of the changed classes>
   ```

   Then load one page or run one Drush command that exercises the changed code.

Done when no `\Drupal::` call is left in a class, the cache rebuild succeeds (the container compiles), `phpcs`
reports nothing and the tests pass.

## Report

Files changed, services added or re-registered, static calls deliberately left in procedural code and why, and the
result of each verify command.
