---
name: create-drupal-service
description: Create a Drupal service class in a custom module and register it in the module's services.yml
argument-hint: <ServiceName> in <module> — <purpose, dependencies, methods>
---

Create the service described here: $ARGUMENTS

The module is required — ask when it is missing. Infer missing dependencies and methods from the purpose and name
what you inferred in the report.

The rules for the class are in `${CLAUDE_PLUGIN_ROOT}/instructions/drupal.md` §5 and `${CLAUDE_PLUGIN_ROOT}/instructions/php.md`; read both
first. This skill is the procedure.

## Steps

1. **Look at the module.** Open `<webroot>/modules/custom/<module>/<module>.services.yml` and one class in
   `src/Service/`. An existing registration style in the module wins over the default below.

2. **Write the class** at `src/Service/<ServiceName>.php`, namespace `Drupal\<module>\Service`:
   - `final`, dependencies as `private readonly` promoted constructor parameters typed by interface;
   - a typed public method per requested operation, each with PHPDoc (`@param`, `@return`, `@throws`);
   - specific exception types; log failures through an injected logger channel.

3. **Register it** in `<module>.services.yml` — by class name with autowiring:

   ```yaml
   services:
     Drupal\<module>\Service\<ServiceName>:
       autowire: true
   ```

   A dependency that autowiring cannot resolve from its type (a logger channel, a cache bin) takes an attribute on
   the constructor parameter: `#[Autowire(service: 'logger.channel.<module>')]`. Register the logger channel when the
   module has none (`drupal.md` §13).

4. **Add an interface** (`src/Service/<ServiceName>Interface.php`) when other classes will mock the service in
   their unit tests: PHPUnit cannot mock a `final` class. Callers then type-hint the interface, and `services.yml`
   aliases it: `Drupal\<module>\Service\<ServiceName>Interface: '@Drupal\<module>\Service\<ServiceName>'`.

5. **Add a unit test** at `tests/src/Unit/Service/<ServiceName>Test.php` covering each public method.

6. **Verify.**

   ```bash
   ddev drush cr
   ddev drush php:eval 'var_dump(\Drupal::service(\Drupal\<module>\Service\<ServiceName>::class) !== NULL);'
   ddev exec vendor/bin/phpcs --standard=Drupal,DrupalPractice <files you created>
   ddev exec vendor/bin/phpunit <test file>
   ```

Done when the container returns the service (`bool(true)`), `phpcs` reports nothing and the test passes.

## Report

Files created or changed, the service ID, anything inferred from an incomplete request, and the result of each
verify command.
