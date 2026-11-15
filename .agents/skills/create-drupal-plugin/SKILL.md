---
name: create-drupal-plugin
description: Create a Drupal plugin class (Block, FieldWidget, FieldFormatter, Condition, QueueWorker, etc.) in a custom module
argument-hint: <type> <plugin_id> in <module> — <purpose>
---

Create the plugin described here: $ARGUMENTS

The module and the plugin type are required — ask when either is missing. Infer the rest from the purpose and name
what you inferred in the report.

The rules for the class are in `.agents/instructions/drupal.md` §9 and `.agents/instructions/php.md`; read both
first. This skill is the procedure.

## Steps

1. **Find the plugin type's contract in core**, not from memory: its attribute class, base class and directory.
   Open an existing core plugin of the same type and copy its shape.

   | Type            | Attribute                                    | Base class            | Directory                          |
   |-----------------|----------------------------------------------|-----------------------|------------------------------------|
   | Block           | `Drupal\Core\Block\Attribute\Block`          | `BlockBase`           | `src/Plugin/Block/`                |
   | Field widget    | `Drupal\Core\Field\Attribute\FieldWidget`    | `WidgetBase`          | `src/Plugin/Field/FieldWidget/`    |
   | Field formatter | `Drupal\Core\Field\Attribute\FieldFormatter` | `FormatterBase`       | `src/Plugin/Field/FieldFormatter/` |
   | Condition       | `Drupal\Core\Condition\Attribute\Condition`  | `ConditionPluginBase` | `src/Plugin/Condition/`            |
   | Queue worker    | `Drupal\Core\Queue\Attribute\QueueWorker`    | `QueueWorkerBase`     | `src/Plugin/QueueWorker/`          |

   Any other type: locate its plugin manager (`grep -r "DefaultPluginManager" <webroot>/core <webroot>/modules`) and
   read the attribute and subdirectory from the manager's constructor.

2. **Write the class** in that directory:
   - a PHP attribute directly above the class, labels as `new TranslatableMarkup('…')`. Core plugin types are
     discovered by attribute on Drupal 10.3+; write a docblock annotation only when the type has no attribute class
     yet;
   - `final`, extending the type's base class and implementing every abstract method;
   - services through `ContainerFactoryPluginInterface`: the constructor takes the base class's own constructor
     arguments followed by the services and passes the former to `parent::__construct()`; a static `create()` builds
     it. Field widgets and formatters have more base arguments than `($configuration, $plugin_id,
     $plugin_definition)` — copy them from the base class. Give injected properties names the base class does not
     use (`drupal.md` §5, "Inherited properties").

3. **Configuration.** A plugin with settings implements `defaultConfiguration()` and its form methods, and gets a
   schema entry in `config/schema/<module>.schema.yml` (`block.settings.<plugin_id>`, `field.widget.settings.<id>`,
   `field.formatter.settings.<id>`, `condition.plugin.<id>`). Config without schema fails config validation and
   kernel tests.

4. **Output.** A block or formatter that renders markup returns a render array with `#theme` and `#cache`
   (tags, contexts, max-age) and gets a Twig template registered through `hook_theme()` (`twig.md` §2). Blocks expose
   cache metadata through `getCacheTags()`, `getCacheContexts()` and `getCacheMaxAge()`.

5. **Verify.**

   ```bash
   ddev drush cr
   ddev drush php:eval 'var_dump(\Drupal::service("<manager>")->hasDefinition("<plugin_id>"));'
   ddev exec vendor/bin/phpcs --standard=Drupal,DrupalPractice <files you created>
   ```

`<manager>` is the type's plugin manager service: `plugin.manager.block`, `plugin.manager.field.widget`,
`plugin.manager.field.formatter`, `plugin.manager.condition`, `plugin.manager.queue_worker`.

Done when the plugin manager reports the definition (`bool(true)`) and `phpcs` reports nothing.

## Report

Files created or changed, the plugin ID, where the plugin is used in the UI (block layout, field display, …),
anything inferred from an incomplete request, and the result of each verify command.
