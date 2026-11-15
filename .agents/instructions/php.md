# PHP 8.3+ Coding Standards for Drupal 10/11

## 1. File Structure & Declarations

### Strict Types Declaration

Every PHP file **must** start with `declare(strict_types=1);`:

```php
<?php

declare(strict_types=1);

namespace Drupal\my_module;
```

### File Headers

Add a file-level PHPDoc block after the `declare` statement for non-trivial files.

---

## 2. Naming Conventions

### Classes & Namespaces

- **PascalCase** for class names: `MyServiceClass`
- Namespace follows Drupal convention: `Drupal\[my_module]\[SubNamespace]`
- Singular names for service classes: `UserService` not `UsersService`

### Methods & Functions

- **camelCase** for methods: `getUserById()`, `processData()`
- **lowercase_with_underscores** for procedural hook implementations: `mymodule_form_alter()`

### Constants & Variables

- **UPPERCASE_WITH_UNDERSCORES** for class constants: `const DEFAULT_TIMEOUT = 30;`
- Drupal splits variable-style casing by scope:
  - **camelCase** for class properties and promoted constructor parameters: `$this->entityTypeManager`,
    `private readonly Connection $database`
  - **camelCase** for your own method parameters: `getUser(int $userId)`
  - Parameters of overridden/inherited Drupal signatures keep their canonical names: `$form_state`, `$form_id`,
    `$plugin_id`, `$plugin_definition` — do not rename these
  - **snake_case** for local variables and procedural code: `$user_id`, `$is_active`, `$new_value`

---

## 3. Type Declarations

### Return Types

Always declare return types for all methods and functions:

```php
public function getUserById(int $id): ?UserInterface {
  // ...
}

public function validateEmail(string $email): bool {
  // ...
}

public function processItems(array $items): void {
  // ...
}
```

### Parameter Types

Always declare parameter types. Avoid `mixed` unless absolutely necessary:

```php
private function processData(string $input, int $count): void {
  // ...
}
```

### Property Types

Always declare types for class properties. Property names use camelCase:

```php
private string $name;
protected int $count = 0;
public bool $isActive;
```

### Constructor Promotion

Use PHP 8.x constructor promotion with `private readonly`. Promoted parameters use camelCase:

```php
public function __construct(
  private readonly Connection $database,
  private readonly EntityTypeManagerInterface $entityTypeManager,
  private readonly LoggerInterface $logger,
) {}
```

---

## 4. PHPDoc Blocks

### Class Documentation

```php
/**
 * Provides user management functionality.
 *
 * This service handles user creation, deletion, and updates.
 */
final class UserService {
  // ...
}
```

### Method Documentation

Every method parameter name uses camelCase; document each `@param`, `@return`, and `@throws`:

```php
/**
 * Retrieves a user by their ID.
 *
 * @param int $userId
 *   The user ID to retrieve.
 *
 * @return \Drupal\user\UserInterface|null
 *   The user object, or NULL if not found.
 *
 * @throws \Drupal\Core\Entity\EntityStorageException
 *   If the entity load fails.
 */
public function getUser(int $userId): ?UserInterface {
  // ...
}
```

### Hook Documentation (OOP hooks)

On Drupal 11.1+ hooks are OOP classes in `src/Hook/`, annotated with `#[Hook(...)]` (on Drupal 10.x they stay
procedural in `.module`, documented the same way). Each implementation still
carries a standard `Implements hook_...()` docblock. Procedural `.module` hooks are the legacy alternative — pick one
approach per module and keep it consistent (see the main Drupal doc §3).

```php
<?php

declare(strict_types=1);

namespace Drupal\mymodule\Hook;

use Drupal\Core\Entity\EntityInterface;
use Drupal\Core\Hook\Attribute\Hook;

/**
 * Hook implementations for mymodule.
 */
final class UserHooks {

  /**
   * Implements hook_ENTITY_TYPE_insert() for users.
   */
  #[Hook('user_insert')]
  public function insert(EntityInterface $entity): void {
    // ...
  }

}
```

---

## 5. Dependency Injection

### Service Classes

Always use constructor injection. Never use `\Drupal::service()` in classes:

```php
/**
 * Service for managing user data.
 */
final class UserService {

  /**
   * Constructor.
   *
   * @param \Drupal\Core\Database\Connection $database
   *   The database service.
   * @param \Drupal\Core\Entity\EntityTypeManagerInterface $entityTypeManager
   *   The entity type manager service.
   */
  public function __construct(
    private readonly Connection $database,
    private readonly EntityTypeManagerInterface $entityTypeManager,
  ) {}

}
```

### Registering Services

Service classes live in the module's `src/Service/` folder (namespace `Drupal\<module>\Service`); controllers,
hooks, plugins, forms, Drush commands, event subscribers and Twig extensions keep their own folders. See
[`drupal.md`](drupal.md) §5 for the full rule.

Static helper classes (constants and/or static methods, not services) live in `src/Utility/` (namespace
`Drupal\<module>\Utility`). No classes in the root of `src/`.

```yaml
services:
  mymodule.user_service:
    class: Drupal\mymodule\Service\UserService
    arguments:
      - '@database'
      - '@entity_type.manager'
```

---

## 6. Controllers

Controllers should only validate input, call services, and return responses. Never serialize an entity object directly
into a `JsonResponse` — build a prepared array of the values you intend to expose:

```php
/**
 * Controller for user operations.
 */
final class UserController extends ControllerBase {

  /**
   * Constructor.
   */
  public function __construct(
    private readonly UserService $userService,
  ) {}

  /**
   * {@inheritdoc}
   */
  public static function create(ContainerInterface $container): self {
    return new self(
      $container->get('mymodule.user_service'),
    );
  }

  /**
   * Returns user data as JSON.
   */
  public function getUser(int $userId): JsonResponse {
    try {
      $user = $this->userService->getUser($userId);
      if ($user === NULL) {
        return new JsonResponse(['error' => 'Not found'], 404);
      }
      $payload = [
        'id' => (int) $user->id(),
        'name' => $user->getAccountName(),
        'email' => $user->getEmail(),
      ];
      return new JsonResponse($payload);
    }
    catch (\Exception $e) {
      return new JsonResponse(['error' => $e->getMessage()], 400);
    }
  }

}
```

---

## 7. Drupal APIs

### Database Queries

Use the Database API via dependency injection with prepared statements:

```php
// ❌ WRONG
$result = \Drupal::database()->query("SELECT * FROM users WHERE id = $id");

// ✅ CORRECT
$result = $this->database->query(
  'SELECT * FROM {users} WHERE id = :id',
  [':id' => $id]
);
```

### Entity Management

```php
$user = $this->entityTypeManager
  ->getStorage('user')
  ->load($userId);
```

---

## 8. Error Handling

### Exceptions

Throw specific exception types. Document them in PHPDoc:

```php
/**
 * @throws \Drupal\Core\Entity\EntityStorageException
 * @throws \InvalidArgumentException
 */
public function processUser(int $userId): void {
  if ($userId <= 0) {
    throw new \InvalidArgumentException('User ID must be positive');
  }
}
```

### Logging

```php
$this->logger->info('User @id processed', ['@id' => $userId]);
$this->logger->error('Failed to process user @id', ['@id' => $userId]);
```

---

## 9. Code Style & Formatting

Formatting follows the project's `.editorconfig` (if present). Code you write must survive the IDE's reformat on
save and `phpcs --standard=Drupal,DrupalPractice` unchanged.

### Spacing & Indentation

- **2 spaces** for indentation (Drupal standard)
- Blank lines between methods
- Lines under 80 characters (Drupal Coder standard). Long lines are flagged by
  `phpcs --standard=Drupal`; wrap arguments or extract variables to stay within the limit.

### Arrays

- Short array syntax `[]` (not `array()`)
- Trailing commas in multiline arrays:

```php
$config = [
  'id' => 'user_1',
  'name' => 'John Doe',
  'email' => 'john@example.com',
];
```

### Control Structures

- Use `elseif` (not `else if`)
- Always use braces, even for single-line blocks
- Avoid deeply nested conditions (max 3–4 levels)

Local boolean variables use snake_case:

```php
if ($is_active) {
  $this->doSomething();
}
elseif ($is_pending) {
  $this->doOtherThing();
}
else {
  $this->doDefault();
}
```

---

## 10. Security Best Practices

### Input Sanitization

Always sanitize user input. Never trust `$_GET`, `$_POST`, or raw form values:

```php
use Drupal\Component\Utility\Xss;

$safe_html = Xss::filter($html_input);
```

### Output Escaping

```php
use Drupal\Component\Utility\Html;

echo Html::escape($variable);
```

### Permissions

Throw `AccessDeniedHttpException` (import it) from controllers and access callbacks:

```php
use Symfony\Component\HttpKernel\Exception\AccessDeniedHttpException;

if (!$this->currentUser->hasPermission('manage users')) {
  throw new AccessDeniedHttpException();
}
```

---

## 11. Testing

### Test Structure

- Unit tests in `tests/src/Unit/`
- Kernel tests in `tests/src/Kernel/`
- Test classes: `[ClassName]Test` (e.g., `UserServiceTest`)
- Test methods: `test[MethodName][Scenario]` (e.g., `testGetUserByIdNotFound`)

### Test Coverage

Aim for 80%+ on services and business logic:

```php
/**
 * @covers \Drupal\mymodule\Service\UserService
 */
final class UserServiceTest extends UnitTestCase {

  /**
   * Tests successful user retrieval.
   */
  public function testGetUserByIdSuccess(): void {
    // Arrange, Act, Assert.
  }

  /**
   * Tests the user not found scenario.
   */
  public function testGetUserByIdNotFound(): void {
    // Arrange, Act, Assert.
  }

}
```

---

## 12. Quick Reference Checklist

- [ ] File starts with `declare(strict_types=1);`
- [ ] All classes, methods, properties have type declarations
- [ ] All public/protected methods have PHPDoc blocks
- [ ] Classes use constructor dependency injection
- [ ] No `\Drupal::service()` calls in classes
- [ ] Business logic in services, not controllers
- [ ] Database queries use prepared statements
- [ ] Proper error handling with specific exceptions
- [ ] User permissions checked for sensitive operations
- [ ] Code follows Drupal Coding Standards
- [ ] Tests written for new business logic
