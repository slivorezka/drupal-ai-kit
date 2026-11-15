---
name: create-drupal-plugin
description: Create a Drupal plugin class (Block, FieldWidget, Condition, etc.)
argument-hint: <type> <plugin_id> in <module> — <purpose>
---

You are a Drupal 10/11 expert. Create a well-structured Drupal plugin class following best practices, plugin architecture
patterns, and PHP 8.3+ standards.

Parse the following input for plugin details: $ARGUMENTS

The input should contain: plugin type (Block, Field, Views, Condition, etc.), plugin ID, module name, purpose, and any
custom methods. If details are missing, infer reasonable defaults.

## Requirements

### Class Structure

1. Start with `declare(strict_types=1);`
2. Namespace: `Drupal\{my_module}\Plugin\{PluginType}\{PluginClassName}`
3. Use a PHP attribute (`#[Block]`, `#[FieldWidget]`, etc.), not a docblock annotation. Drupal 10.2+ discovers plugins by attribute; annotations are deprecated. Include:

- `id: '{plugin_id}'`
- `admin_label: new TranslatableMarkup('{Human Readable Label}')`
- Other type-specific properties

4. Extend the correct base class (`BlockBase`, `WidgetBase`, etc.)
5. Implement `ContainerFactoryPluginInterface` if dependencies are needed
6. Use `create()` method for dependency injection

### Plugin Types Reference

**Block Plugin:**

```php
use Drupal\Core\Block\Attribute\Block;
use Drupal\Core\StringTranslation\TranslatableMarkup;

#[Block(
  id: 'my_block',
  admin_label: new TranslatableMarkup('My Block'),
  category: new TranslatableMarkup('Custom'),
)]
```

Methods: `build()`, `blockAccess()`, `defaultConfiguration()`, `blockForm()`, `blockSubmit()`

**Field Widget Plugin:**

```php
use Drupal\Core\Field\Attribute\FieldWidget;

#[FieldWidget(
  id: 'my_widget',
  label: new TranslatableMarkup('My Widget'),
  field_types: ['text'],
)]
```

Methods: `formElement()`, `massageFormValues()`

**Condition Plugin:**

```php
use Drupal\Core\Condition\Attribute\Condition;

#[Condition(
  id: 'my_condition',
  label: new TranslatableMarkup('My Condition'),
)]
```

Methods: `evaluate()`, `buildConfigurationForm()`

### Code Quality

- Comprehensive PHPDoc blocks for class and all methods
- Include `@param`, `@return`, `@throws` tags
- Use typed properties and return types throughout
- Implement all required abstract methods from base class
- Include configuration form with validation if applicable
- Use translatable strings with `$this->t()` or `new TranslatableMarkup()` in attributes

### Output

Generate all of the following:

1. **Complete PHP Plugin Class** — Full file with attribute, constructor, `create()` method, and all required methods.

2. **Template File** (if applicable) — Twig template for the plugin output with proper BEM naming and documentation.

3. **Plugin Discovery Notes** — How Drupal discovers this plugin (directory structure, attribute).

4. **Usage Example** — How to use/configure the plugin.

### File Location

Plugin files must be in the correct directory for Drupal discovery:

```
src/Plugin/Block/MyBlock.php
src/Plugin/Field/FieldWidget/MyWidget.php
src/Plugin/Condition/MyCondition.php
```

### Validation Checklist

- [ ] Strict types declared
- [ ] Proper namespace and directory
- [ ] Correct base class extended
- [ ] Plugin attribute present and correct (no docblock annotation)
- [ ] All required abstract methods implemented
- [ ] `create()` method for DI (if needed)
- [ ] All methods have return types
- [ ] PHPDoc on class and all methods
- [ ] Configuration form with validation (if applicable)
- [ ] Plugin ID is unique
- [ ] Translatable strings use `$this->t()` or `TranslatableMarkup`

