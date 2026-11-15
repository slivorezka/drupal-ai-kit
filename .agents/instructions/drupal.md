# Comprehensive Drupal Instructions (10.3+ / 11)

## 1. Project Foundation

### Overview

- **Framework**: Drupal 10.3+ / 11.x (check `drupal/core` in `composer.json`)
- **PHP Version**: 8.3+
- **Stack**: LAMP (Linux, Apache, MySQL/MariaDB, PHP)
- **Goal**: Clean, modular, testable, and secure code adhering to Drupal best practices

### Key Principles

- **KISS (Keep It Simple, Stupid)**: Write clear, concise, and maintainable code
- **DRY (Don't Repeat Yourself)**: Reuse code through hooks, plugins, and services
- **SOLID**: Single Responsibility, Open/Closed, Liskov Substitution, Interface Segregation, Dependency Inversion
- **Security First**: Sanitize input, escape output, check permissions
- **Testability**: Write code that's easy to test with PHPUnit
- **Drupal Standards**: Follow official [Drupal Coding Standards](https://www.drupal.org/docs/develop/standards)

---

## 2. Module Development Structure

### Anatomy of a Custom Module

On Drupal 11.1+ use OOP hooks: hook implementations live in `src/Hook/` rather than the `.module` file. On
Drupal 10.x hooks stay procedural in `.module`. See §3 for details.

```
my_module/
├── src/
│   ├── Controller/
│   │   └── MyController.php
│   ├── Service/
│   │   └── MyService.php
│   ├── Utility/
│   │   └── MyHelper.php # Static helpers only (no services).
│   ├── Form/
│   │   └── MyForm.php
│   ├── Plugin/
│   │   ├── Block/
│   │   ├── Field/
│   │   └── views/
│   ├── Entity/
│   │   └── MyEntity.php
│   ├── Event/
│   │   └── MyCustomEvent.php
│   ├── EventSubscriber/
│   │   └── MyEventSubscriber.php
│   └── Hook/
│       ├── MyHooks.php
│       └── ThemeHooks.php # Optional: split hooks by concern.
├── config/
│   └── schema/
│       └── my_module.schema.yml # Schema for the module's config and plugin settings.
├── templates/
│   └── my-template.html.twig
├── css/
│   └── my-module.css
├── js/
│   └── my-module.js
├── tests/
│   └── src/
│       ├── Unit/
│       └── Kernel/
├── my_module.info.yml
├── my_module.install
├── my_module.services.yml
├── my_module.routing.yml
├── my_module.permissions.yml
├── my_module.links.menu.yml
└── my_module.libraries.yml
```

Install-time hooks — `hook_install()`, `hook_uninstall()`, `hook_update_N()`, `hook_schema()`,
`hook_requirements()` — **cannot** be OOP hooks and must remain procedural in the `.install` file even on
Drupal 11.1+. They run before the container/hook attributes are available. Everything else uses OOP hooks on 11.1+
(see §3).

### Module Files Description

#### `my_module.info.yml`

```yaml
name: My Module
description: Provides custom functionality
package: Custom
type: module
core_version_requirement: ^10.3 || ^11
dependencies:
  - drupal:node
  - drupal:user
```

#### `my_module.services.yml`

Services are registered by class name with autowiring; the class name is the service ID (see §5). The
`EntityService` from §7:

```yaml
services:
  Drupal\my_module\Service\EntityService:
    autowire: true
```

#### `my_module.routing.yml`

```yaml
my_module.my_route:
  path: '/my-path/{id}'
  defaults:
    _controller: '\Drupal\my_module\Controller\MyController::page'
    _title: 'My Page'
  requirements:
    _permission: 'access content'
    id: '\d+'
```

#### `my_module.permissions.yml`

```yaml
'my custom permission':
  title: 'My Custom Permission'
  description: 'Description of the permission'
  restrict access: false
```

#### `my_module.libraries.yml`

```yaml
my_library:
  css:
    theme:
      css/my-module.css: { }
  js:
    js/my-module.js:
      attributes:
        defer: true
  dependencies:
    - core/drupal
    - core/once
```

---

## 3. Hooks & Events

### Hook Implementation

On **Drupal 11.1+** use **OOP hooks**: hook implementations are methods on a class in `src/Hook/`, annotated with the
`#[Hook(...)]` attribute. Procedural `.module` hooks are the legacy alternative — prefer OOP hooks for new code and keep
the approach consistent across the module. On **Drupal 10.x** OOP hooks are not available: implement hooks as
procedural functions in `my_module.module` and delegate the logic to injected services.

**Preprocess hooks** (`hook_preprocess()`, `hook_preprocess_HOOK()`) can be OOP from **Drupal 11.2**. On 11.1 a
`#[Hook('preprocess_…')]` attribute throws an exception: keep preprocess hooks procedural in `.module` there. Themes
keep their preprocess functions in `<theme>.theme`.

Hooks may be split across multiple classes in `src/Hook/` — group them by concern rather than putting everything in one
class.

**Exception:** install-time hooks (`hook_install()`, `hook_uninstall()`, `hook_update_N()`, `hook_schema()`,
`hook_requirements()`) cannot be OOP hooks — keep them procedural in the `.install` file (see §2).

```php
<?php

declare(strict_types=1);

namespace Drupal\my_module\Hook;

use Drupal\Core\Entity\EntityInterface;
use Drupal\Core\Form\FormStateInterface;
use Drupal\Core\Hook\Attribute\Hook;

/**
 * Hook implementations for my_module.
 */
final class MyHooks {

  /**
   * Implements hook_ENTITY_TYPE_insert() for nodes.
   */
  #[Hook('node_insert')]
  public function nodeInsert(EntityInterface $entity): void {
    // React to node creation.
  }

  /**
   * Implements hook_form_FORM_ID_alter().
   */
  #[Hook('form_node_form_alter')]
  public function formNodeFormAlter(array &$form, FormStateInterface $form_state, string $form_id): void {
    // Modify node form.
  }

  /**
   * Implements hook_preprocess_HOOK() for nodes.
   *
   * OOP preprocess hooks need Drupal 11.2+.
   */
  #[Hook('preprocess_node')]
  public function preprocessNode(array &$variables): void {
    // Prepare variables for node template.
  }

}
```

### Event Subscribers

Use event subscribers instead of hooks when possible. Define the event class explicitly and reference its constant.
Event classes live in `src/Event/`, subscribers in `src/EventSubscriber/`.

```php
<?php

declare(strict_types=1);

namespace Drupal\my_module\Event;

use Drupal\Component\EventDispatcher\Event;

/**
 * Event dispatched when my_module performs a custom action.
 */
final class MyCustomEvent extends Event {

  public const string EVENT_NAME = 'my_module.custom_event';

  /**
   * Constructs a MyCustomEvent.
   *
   * @param array $data
   *   The event payload.
   */
  public function __construct(
    public readonly array $data,
  ) {}

}
```

```php
<?php

declare(strict_types=1);

namespace Drupal\my_module\EventSubscriber;

use Drupal\my_module\Event\MyCustomEvent;
use Symfony\Component\EventDispatcher\EventSubscriberInterface;

/**
 * Event subscriber for custom events.
 */
final class MyEventSubscriber implements EventSubscriberInterface {

  /**
   * {@inheritdoc}
   */
  public static function getSubscribedEvents(): array {
    return [
      MyCustomEvent::EVENT_NAME => 'onCustomEvent',
    ];
  }

  /**
   * Handles the custom event.
   */
  public function onCustomEvent(MyCustomEvent $event): void {
    // Handle event.
  }

}
```

Register in `my_module.services.yml`:

```yaml
services:
  Drupal\my_module\EventSubscriber\MyEventSubscriber:
    autowire: true
    tags:
      - { name: 'event_subscriber' }
```

---

## 4. Controllers & Routing

Controllers should be lightweight request handlers that delegate to services.

```php
<?php

declare(strict_types=1);

namespace Drupal\my_module\Controller;

use Drupal\Core\Controller\ControllerBase;
use Drupal\my_module\Service\DataProcessor;
use Symfony\Component\DependencyInjection\ContainerInterface;
use Symfony\Component\HttpFoundation\JsonResponse;

/**
 * Provides controller methods for my module.
 */
final class MyController extends ControllerBase {

  /**
   * Constructor.
   */
  public function __construct(
    private readonly DataProcessor $dataProcessor,
  ) {}

  /**
   * {@inheritdoc}
   */
  public static function create(ContainerInterface $container): self {
    return new self(
      $container->get(DataProcessor::class),
    );
  }

  /**
   * Responds with a page.
   */
  public function page(): array {
    $data = $this->dataProcessor->processData([]);
    return [
      '#theme' => 'my_template',
      '#data' => $data,
    ];
  }

  /**
   * Responds with JSON.
   */
  public function jsonResponse(): JsonResponse {
    $data = $this->dataProcessor->processData([]);
    return new JsonResponse($data);
  }

}
```

---

## 5. Services & Dependency Injection

Services encapsulate business logic and are injected where needed.

**Location rule:** every service class lives in the module's `src/Service/` folder,
namespace `Drupal\<module>\Service` — not in the root of `src/` or in an ad-hoc folder. Exceptions are classes with
their own conventional folder, even when they are registered as services: controllers (`src/Controller/`), hooks
(`src/Hook/`), plugins (`src/Plugin/`), forms (`src/Form/`), Drush commands (`src/Drush/Commands/`), event
subscribers (`src/EventSubscriber/`), Twig extensions (`src/Twig/`). Static helper classes that are not registered
as services go to `src/Utility/` instead (see below). Register services by their class name with autowiring:

```yaml
services:
  Drupal\my_module\Service\DataProcessor:
    autowire: true
```

**Utility rule:** static helper classes — only constants and/or static methods, no state, not
registered as services (e.g. `Drupal\my_module\Utility\Utm`, `Drupal\my_module\Utility\BrandColor`) — live
in the module's `src/Utility/` folder, namespace `Drupal\<module>\Utility`. A helper that needs other services is a
service, not a utility: move it to `src/Service/` and inject it. The root of `src/` holds no classes; every class
goes into a folder by its role (`Service`, `Utility`, `Hook`, `Controller`, `Plugin`, `BundleClass`, …).

**Inherited properties:** Drupal's base classes already declare untyped `protected` properties. Promoting a
constructor parameter with the same name (`private readonly EntityTypeManagerInterface $entityTypeManager` in a
controller) is a fatal error — the child may not narrow the visibility or add a type.

| Base class       | Properties it declares                                                                                                                               |
|------------------|------------------------------------------------------------------------------------------------------------------------------------------------------|
| `ControllerBase` | `$entityTypeManager`, `$entityFormBuilder`, `$configFactory`, `$keyValue`, `$currentUser`, `$stateService`, `$moduleHandler`, `$formBuilder`, `$languageManager` |
| `FormBase`       | `$configFactory`, `$requestStack`, `$routeMatch`                                                                                                     |
| `PluginBase`     | `$configuration`, `$pluginId`, `$pluginDefinition`                                                                                                   |
| all three        | `$messenger`, `$stringTranslation`; controllers and forms also `$loggerFactory`, `$redirectDestination`                                              |

In a subclass inject the dependency under a name the base class does not use (`$nodeStorage`, `$account`,
`$settings`), or call the inherited accessor (`$this->entityTypeManager()`, `$this->currentUser()`,
`$this->config()`, `$this->messenger()`, `$this->t()`). Check the base class before naming a property.

**`final` and mocking:** classes are `final` by default. PHPUnit cannot mock a `final` class, so a service that
other classes mock in their unit tests gets an interface (`DataProcessorInterface`), callers type-hint the
interface, and `services.yml` aliases it to the class.

```php
<?php

declare(strict_types=1);

namespace Drupal\my_module\Service;

use Drupal\Core\Database\Connection;
use Drupal\Core\Entity\EntityTypeManagerInterface;
use Psr\Log\LoggerInterface;
use Symfony\Component\DependencyInjection\Attribute\Autowire;

/**
 * Service for data processing.
 */
final class DataProcessor {

  /**
   * Constructor.
   */
  public function __construct(
    private readonly Connection $database,
    private readonly EntityTypeManagerInterface $entityTypeManager,
    #[Autowire(service: 'logger.channel.my_module')]
    private readonly LoggerInterface $logger,
  ) {}

  /**
   * Processes data.
   *
   * @param array $data
   *   Data to process.
   *
   * @return array
   *   Processed data.
   */
  public function processData(array $data): array {
    try {
      $this->logger->info('Processing data');
      $result = [];
      return $result;
    }
    catch (\Exception $e) {
      $this->logger->error('Error: @message', ['@message' => $e->getMessage()]);
      throw $e;
    }
  }

}
```

Autowiring resolves each constructor argument from its type. An argument whose type alone does not identify a
service — a logger channel, a cache bin — names it with `#[Autowire(service: '…')]`; the logger channel itself is
registered in §13. The class is fetched from the container by its name: `$container->get(DataProcessor::class)`.

---

## 6. Forms & Form Handling

```php
<?php

declare(strict_types=1);

namespace Drupal\my_module\Form;

use Drupal\Core\Form\FormBase;
use Drupal\Core\Form\FormStateInterface;
use Drupal\my_module\Service\DataProcessor;
use Symfony\Component\DependencyInjection\ContainerInterface;

/**
 * Provides a form for data submission.
 */
final class MyForm extends FormBase {

  /**
   * Constructor.
   */
  public function __construct(
    private readonly DataProcessor $dataProcessor,
  ) {}

  /**
   * {@inheritdoc}
   */
  public static function create(ContainerInterface $container): self {
    return new self(
      $container->get(DataProcessor::class),
    );
  }

  /**
   * {@inheritdoc}
   */
  public function getFormId(): string {
    return 'my_module_my_form';
  }

  /**
   * {@inheritdoc}
   */
  public function buildForm(array $form, FormStateInterface $form_state): array {
    $form['name'] = [
      '#type' => 'textfield',
      '#title' => $this->t('Name'),
      '#required' => TRUE,
    ];

    $form['email'] = [
      '#type' => 'email',
      '#title' => $this->t('Email'),
      '#required' => TRUE,
    ];

    $form['actions']['submit'] = [
      '#type' => 'submit',
      '#value' => $this->t('Submit'),
    ];

    return $form;
  }

  /**
   * {@inheritdoc}
   */
  public function validateForm(array &$form, FormStateInterface $form_state): void {
    $email = $form_state->getValue('email');
    if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
      $form_state->setErrorByName('email', $this->t('Invalid email'));
    }
  }

  /**
   * {@inheritdoc}
   */
  public function submitForm(array &$form, FormStateInterface $form_state): void {
    $data = $form_state->getValues();
    $this->dataProcessor->processData($data);
    $this->messenger()->addStatus($this->t('Form submitted successfully'));
  }

}
```

---

## 7. Entities & Entity API

Use specific interface types (e.g. `NodeInterface`) rather than the generic `object` when the entity type is known.

```php
<?php

declare(strict_types=1);

namespace Drupal\my_module\Service;

use Drupal\Core\Entity\EntityTypeManagerInterface;
use Drupal\node\NodeInterface;

/**
 * Service for entity operations.
 */
final class EntityService {

  /**
   * Constructor.
   */
  public function __construct(
    private readonly EntityTypeManagerInterface $entityTypeManager,
  ) {}

  /**
   * Loads a node by ID.
   */
  public function getNode(int $nid): ?NodeInterface {
    return $this->entityTypeManager
      ->getStorage('node')
      ->load($nid);
  }

  /**
   * Loads multiple nodes.
   */
  public function getNodes(array $nids): array {
    return $this->entityTypeManager
      ->getStorage('node')
      ->loadMultiple($nids);
  }

  /**
   * Creates and saves a new node.
   */
  public function createNode(array $values): NodeInterface {
    $node = $this->entityTypeManager
      ->getStorage('node')
      ->create($values);
    $node->save();
    return $node;
  }

  /**
   * Queries entities.
   */
  public function queryNodes(string $type): array {
    $query = $this->entityTypeManager
      ->getStorage('node')
      ->getQuery();

    return $query
      ->condition('type', $type)
      ->condition('status', 1)
      ->sort('created', 'DESC')
      ->accessCheck(TRUE)
      ->execute();
  }

}
```

---

## 8. Database & Queries

Always use prepared statements to prevent SQL injection. `Insert::execute()` returns the last insert ID as a string;
cast it to satisfy a declared `int` return type under `strict_types=1`.

```php
<?php

declare(strict_types=1);

namespace Drupal\my_module\Service;

use Drupal\Core\Database\Connection;

/**
 * Service for database operations.
 */
final class DatabaseService {

  /**
   * Constructor.
   */
  public function __construct(
    private readonly Connection $database,
  ) {}

  /**
   * Inserts a record.
   */
  public function insertRecord(array $fields): int {
    return (int) $this->database->insert('my_module_table')
      ->fields($fields)
      ->execute();
  }

  /**
   * Selects records.
   */
  public function getRecords(int $limit = 10): array {
    return $this->database->select('my_module_table', 'mmt')
      ->fields('mmt')
      ->condition('mmt.status', 1)
      ->range(0, $limit)
      ->orderBy('mmt.created', 'DESC')
      ->execute()
      ->fetchAllAssoc('id');
  }

  /**
   * Updates a record.
   */
  public function updateRecord(int $id, array $fields): int {
    return $this->database->update('my_module_table')
      ->fields($fields)
      ->condition('id', $id)
      ->execute();
  }

  /**
   * Deletes a record.
   */
  public function deleteRecord(int $id): int {
    return $this->database->delete('my_module_table')
      ->condition('id', $id)
      ->execute();
  }

}
```

---

## 9. Plugins

### Block Plugin

The `#[Block(...)]` attribute must sit directly above the class declaration (column 0) and both it and
`TranslatableMarkup` must be imported.

```php
<?php

declare(strict_types=1);

namespace Drupal\my_module\Plugin\Block;

use Drupal\Core\Block\Attribute\Block;
use Drupal\Core\Block\BlockBase;
use Drupal\Core\Plugin\ContainerFactoryPluginInterface;
use Drupal\Core\StringTranslation\TranslatableMarkup;
use Drupal\my_module\Service\DataProcessor;
use Symfony\Component\DependencyInjection\ContainerInterface;

/**
 * Provides a custom block.
 */
#[Block(
  id: 'my_module_custom_block',
  admin_label: new TranslatableMarkup('My Custom Block'),
)]
final class CustomBlock extends BlockBase implements ContainerFactoryPluginInterface {

  /**
   * Constructor.
   */
  public function __construct(
    array $configuration,
    string $plugin_id,
    array $plugin_definition,
    private readonly DataProcessor $dataProcessor,
  ) {
    parent::__construct($configuration, $plugin_id, $plugin_definition);
  }

  /**
   * {@inheritdoc}
   */
  public static function create(ContainerInterface $container, array $configuration, $plugin_id, $plugin_definition): self {
    return new self(
      $configuration,
      $plugin_id,
      $plugin_definition,
      $container->get(DataProcessor::class),
    );
  }

  /**
   * {@inheritdoc}
   */
  public function build(): array {
    $data = $this->dataProcessor->processData([]);
    return [
      '#theme' => 'my_block_template',
      '#data' => $data,
    ];
  }

}
```

A plugin with settings (`defaultConfiguration()`) needs a schema entry in `config/schema/my_module.schema.yml`;
config without schema fails validation and kernel tests:

```yaml
block.settings.my_module_custom_block:
  type: block_settings
  label: 'My custom block'
  mapping:
    items_per_page:
      type: integer
      label: 'Items per page'
```

---

## 10. Security Best Practices

### Input Validation & Sanitization

```php
use Drupal\Component\Utility\Xss;

// Validate.
$email = $form_state->getValue('email');
if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
  $form_state->setErrorByName('email', $this->t('Invalid email'));
}

// Sanitize strings.
$safe_html = Xss::filter($html_input);

// Database escaping (automatic with query builder).
$query->condition('email', $email);
```

### Output Escaping

In PHP, import and use `Html::escape()`:

```php
use Drupal\Component\Utility\Html;

echo Html::escape($variable);
```

In Twig, output is auto-escaped:

```twig
{{ variable }} {# Escaped #}
{{ safe_html|raw }} {# Not escaped — use carefully #}
```

### Permission Checking

In routing, use the `_permission` requirement:

```yaml
requirements:
  _permission: 'access content'
```

In code, throw `AccessDeniedHttpException` (import it) when a controller or access callback must deny access:

```php
use Symfony\Component\HttpKernel\Exception\AccessDeniedHttpException;

if (!$this->currentUser()->hasPermission('my permission')) {
  throw new AccessDeniedHttpException();
}
```

---

## 11. Testing

### Unit Tests

Test metadata follows the PHPUnit version of the project's core: attributes (`#[CoversClass]`, `#[Group]`,
`#[DataProvider]`) on Drupal 11 (PHPUnit 10+), docblock annotations (`@covers`, `@group`, `@dataProvider`) on
Drupal 10 (PHPUnit 9). The example uses attributes.

```php
<?php

declare(strict_types=1);

namespace Drupal\Tests\my_module\Unit\Service;

use Drupal\Core\Database\Connection;
use Drupal\Core\Entity\EntityTypeManagerInterface;
use Drupal\Tests\UnitTestCase;
use Drupal\my_module\Service\DataProcessor;
use PHPUnit\Framework\Attributes\CoversClass;
use PHPUnit\Framework\Attributes\Group;
use Psr\Log\LoggerInterface;

/**
 * Tests for DataProcessor service.
 */
#[CoversClass(DataProcessor::class)]
#[Group('my_module')]
final class DataProcessorTest extends UnitTestCase {

  private DataProcessor $dataProcessor;

  /**
   * {@inheritdoc}
   */
  protected function setUp(): void {
    parent::setUp();
    $this->dataProcessor = new DataProcessor(
      $this->createMock(Connection::class),
      $this->createMock(EntityTypeManagerInterface::class),
      $this->createMock(LoggerInterface::class),
    );
  }

  /**
   * Tests processData method.
   */
  public function testProcessDataSuccess(): void {
    $input = ['key' => 'value'];
    $result = $this->dataProcessor->processData($input);
    $this->assertIsArray($result);
  }

}
```

### Running Tests

Use the project's PHPUnit config (see `AGENTS.md`, "Testing"):

```bash
ddev exec vendor/bin/phpunit -c phpunit.xml.dist <webroot>/modules/custom/my_module
ddev exec vendor/bin/phpunit -c phpunit.xml.dist --filter=DataProcessorTest
```

---

## 12. Caching

Inject the cache backend (`cache.default`) and the cache tags invalidator (`cache_tags.invalidator`) rather than
using `\Drupal::` static calls. `CacheBackendInterface` has no `invalidateTags()` method — tag invalidation goes
through the invalidator service.

```php
<?php

declare(strict_types=1);

namespace Drupal\my_module\Service;

use Drupal\Core\Cache\CacheBackendInterface;
use Drupal\Core\Cache\CacheTagsInvalidatorInterface;
use Symfony\Component\DependencyInjection\Attribute\Autowire;

/**
 * Service demonstrating cache usage.
 */
final class CacheService {

  /**
   * Constructor.
   */
  public function __construct(
    #[Autowire(service: 'cache.default')]
    private readonly CacheBackendInterface $cache,
    private readonly CacheTagsInvalidatorInterface $cacheTagsInvalidator,
  ) {}

  /**
   * Stores data with cache tags.
   */
  public function store(string $key, array $data): void {
    $this->cache->set($key, $data, CacheBackendInterface::CACHE_PERMANENT, ['my_module_tag']);
  }

  /**
   * Invalidates the module cache tag.
   */
  public function invalidate(): void {
    $this->cacheTagsInvalidator->invalidateTags(['my_module_tag']);
  }

}
```

Register it in `my_module.services.yml`:

```yaml
services:
  Drupal\my_module\Service\CacheService:
    autowire: true
```

Cache in render arrays:

```php
return [
  '#cache' => [
    'max-age' => 3600,
    'tags' => ['my_module_tag'],
    'contexts' => ['user'],
  ],
];
```

---

## 13. Logging

```php
$this->logger->info('User @uid performed action', ['@uid' => $uid]);
$this->logger->error('Error: @message', ['@message' => $e->getMessage()]);
```

Register the logger channel in services. The service ID must be `logger.channel.my_module` to match the
`#[Autowire]` attribute in §5:

```yaml
services:
  logger.channel.my_module:
    parent: logger.channel_base
    arguments: ['my_module']
```

---

## 14. Configuration Management

```php
// Read config via service.
$config = $this->configFactory->get('my_module.settings');
$value = $config->get('items_per_page');

// Write config.
$this->configFactory->getEditable('my_module.settings')
  ->set('items_per_page', $new_value)
  ->save();
```

Config is exported to `config/sync` and committed, so it holds settings only. API keys, passwords and tokens come
from environment variables through `settings.php` (`$settings['my_module_api_key'] = getenv('MY_MODULE_API_KEY');`,
read with `Settings::get()`), or from the Key module when the project uses it. Every config object has a schema in
`config/schema/my_module.schema.yml`.

---

## 15. Performance Tips

1. **Lazy Loading**: Load entities only when needed
2. **Batch Processing**: Use Batch API for large datasets
3. **Caching**: Cache expensive operations with proper tags/contexts
4. **Database Indexing**: Index frequently queried fields in `hook_schema()`
5. **Select Specific Fields**: Use `->fields('alias', ['field1', 'field2'])` instead of `->fields('alias')`
6. **Batch Entity Loading**: Use `loadMultiple()` instead of `load()` in loops
7. **Asset Aggregation**: Enable CSS/JS aggregation in production

---

## 16. Quick Reference Checklist

### Before Creating a Module

- [ ] Module purpose clearly defined
- [ ] Follows Drupal naming conventions
- [ ] All dependencies declared in `.info.yml`
- [ ] core_version_requirement matches the supported core versions in .info.yml

### Code Quality

- [ ] PHP 8.3+ syntax (typed properties, union types)
- [ ] `declare(strict_types=1);` in all files
- [ ] PHPDoc blocks on all classes and methods
- [ ] Dependency injection used throughout
- [ ] No `\Drupal::` static calls in classes

### Architecture

- [ ] Business logic in services
- [ ] Controllers lightweight
- [ ] Forms use FormBase classes
- [ ] Plugins use proper base classes

### Security

- [ ] Input validated and sanitized
- [ ] Output escaped (auto-escaped in Twig)
- [ ] User permissions checked
- [ ] Database queries use prepared statements

### Testing

- [ ] Unit tests for services
- [ ] Kernel tests for database operations
- [ ] Coverage above 80%
