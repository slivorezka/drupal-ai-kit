---
name: create-drupal-service
description: Create a Drupal service class with services.yml entry
argument-hint: <ServiceName> in <module> — <purpose, dependencies, methods>
---

You are a Drupal 10/11 expert. Create a well-structured Drupal service class following best practices, dependency injection
patterns, and PHP 8.3+ standards.

Parse the following input for service details: $ARGUMENTS

The input should contain: service name, module name, purpose, dependencies, and methods. If any details are missing,
infer reasonable defaults from the service name and purpose.

## Requirements

### Class Structure

1. Start with `declare(strict_types=1);`
2. Namespace: `Drupal\{my_module}\Service\{ServiceName}`
3. Use constructor dependency injection only (no `\Drupal::service()` calls)
4. Use `private readonly` for all injected dependencies
5. All methods must have typed parameters and return types

### Code Quality

- Comprehensive PHPDoc blocks for the class and all methods
- Include `@param`, `@return`, `@throws` tags
- Use camelCase for methods/properties, UPPERCASE_WITH_UNDERSCORES for constants
- Meaningful variable names
- Error handling with specific exceptions
- Logger service for logging

### Output

Generate all of the following:

1. **Complete PHP Service Class** — Full file with opening tag, strict types, namespace, imports, class with all
   methods, and PHPDoc documentation.

2. **Services.yml Entry** — Ready to paste into the module's `*.services.yml`:

```yaml
services:
  {my_module}.{service_name}:
    class: Drupal\{my_module}\Service\{ServiceName}
    arguments:
      - '@dependency1'
      - '@dependency2'
```

3. **Usage Example** — PHP code showing how to inject and use the service in a controller or another class.

### Example Input

```
UserProfileService in user_profiles module — manages user profile CRUD operations with database, entity_type.manager, current_user, logger dependencies. Methods: getUserProfile(userId), updateUserProfile(userId, data), deleteUserProfile(userId), getUserProfiles(limit)
```

### Validation Checklist

- [ ] Strict types declared
- [ ] Proper namespace
- [ ] Constructor injection only
- [ ] All properties typed with `private readonly`
- [ ] All methods have return types
- [ ] PHPDoc on class and all methods
- [ ] Error handling implemented
- [ ] Logging included
- [ ] Services.yml entry provided
- [ ] Usage example provided

