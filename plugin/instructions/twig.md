# Comprehensive Drupal Twig Instructions

## 1. Key Principles

- **Logic-free Templates**: Keep business logic in PHP (controllers, services, preprocess functions)
- **Auto-escaping**: Output is escaped by default to prevent XSS
- **Readability**: Clean, well-documented syntax
- **Reusability**: Build components and reuse them with `include` and `embed`
- **Formatting**: 2-space indentation; no space between a function or filter name and its parenthesis
  (`attach_library('…')`, `|t({…})`)

---

## 2. File Naming & Organization

### Template File Naming

```
templates/
├── my-template.html.twig
├── my-template--variant.html.twig
└── layouts/
    └── my-layout.html.twig
components/
├── card/
│   ├── card.component.yml
│   ├── card.twig
│   └── card.css
└── hero/
    ├── hero.component.yml
    └── hero.twig
```

### Naming Convention

- **Lowercase** with **hyphens** (kebab-case): `my-template.html.twig`
- Double hyphens for variants: `node--article.html.twig`
- Descriptive names: `card-with-image.html.twig`, not `template1.html.twig`

### Template Registration

`hook_theme()` can be implemented as an OOP hook on Drupal 11.1+ (shown below as a `#[Hook('theme')]` method). On
Drupal 10.x implement it as a procedural `my_module_theme()` function in `my_module.module`:

```php
<?php

declare(strict_types=1);

namespace Drupal\my_module\Hook;

use Drupal\Core\Hook\Attribute\Hook;

/**
 * Theme hook implementations for my_module.
 */
final class ThemeHooks {

  /**
   * Implements hook_theme().
   */
  #[Hook('theme')]
  public function theme(): array {
    return [
      'my_template' => [
        'variables' => [
          'title' => NULL,
          'items' => [],
          'description' => NULL,
        ],
      ],
    ];
  }

}
```

---

## 3. Template Structure

### Basic Template

```twig
{#
/**
 * @file
 * Template for displaying a custom component.
 *
 * Available variables:
 * - title (string): The component title.
 * - items (array): List of items to display.
 * - description (string): Component description.
 *
 * @ingroup themeable
 */
#}
<div class="my-component">
  {% if title %}
    <h2 class="my-component__title">{{ title }}</h2>
  {% endif %}

  {% if description %}
    <p class="my-component__description">{{ description }}</p>
  {% endif %}

  {% if items %}
    <ul class="my-component__list">
      {% for item in items %}
        <li class="my-component__item">{{ item }}</li>
      {% endfor %}
    </ul>
  {% else %}
    <p class="my-component__empty">{{ 'No items found'|t }}</p>
  {% endif %}
</div>
```

### File Header Documentation

Every template starts with a documentation block listing its variables:

```twig
{#
/**
 * @file
 * Brief description of template.
 *
 * Available variables:
 * - variable_name (type): Description.
 *
 * @ingroup themeable
 */
#}
```

### Comments

Multi-line comments: `{#` and `#}` on their own lines at the code's indent,
the text indented two more spaces (a `/** … */` file header stays as above):

```twig
{#
  Social network links from the site settings.
  Icons come from the theme's SVG sprite.
#}
```

---

## 4. Output & Escaping

### Auto-escaping (Default)

```twig
{{ title }} {# Safe — HTML special characters escaped #}
{{ user.name }} {# Safe — nested properties escaped #}
{{ content }} {# Safe — Drupal render arrays #}
```

### When NOT to Escape

Use `|raw` **only** for trusted content already escaped in PHP:

```twig
{{ safe_html|raw }} {# Content pre-escaped in PHP #}
{{ content.field_body }} {# Entity render arrays are safe #}
```

### Common Filters

The `escape('url')` strategy encodes a single URL *component* (e.g. a query-string value), not a whole URL — applying
it to a complete link corrupts it. Generate links with the `path()` / `url()` functions or the `link()` function
instead:

```twig
{{ html_content|striptags }}
<a href="{{ path('route.name', {'id': item.id}) }}">{{ 'Details'|t }}</a>
<a href="?q={{ query_value|escape('url') }}">{{ 'Filtered'|t }}</a> {# escape('url') on a component only #}
<div data-title="{{ title|escape('html_attr') }}"></div>
```

---

## 5. Conditionals

```twig
{% if is_active %}
  <span class="badge badge--active">{{ 'Active'|t }}</span>
{% endif %}

{% if logged_in %}
  <p>{{ 'Welcome, @name'|t({'@name': user_name}) }}</p>
{% else %}
  <p><a href="{{ path('user.login') }}">{{ 'Log in'|t }}</a></p>
{% endif %}

{% if status == 'published' %}
  <span>{{ 'Published'|t }}</span>
{% elseif status == 'draft' %}
  <span>{{ 'Draft'|t }}</span>
{% else %}
  <span>{{ 'Archived'|t }}</span>
{% endif %}

{# Null coalescing #}
{{ title ?? 'Untitled'|t }}
```

---

## 6. Loops

```twig
{% for item in items %}
  <div>{{ item }}</div>
{% else %}
  <p>{{ 'No items found'|t }}</p>
{% endfor %}

{# Loop variables #}
<ul>
  {% for item in items %}
    <li class="{{ loop.index is even ? 'even' : 'odd' }}">
      {{ loop.index }} / {{ loop.length }}: {{ item }}
    </li>
  {% endfor %}
</ul>
```

---

## 7. Drupal-Specific Features

### Translation

```twig
{{ 'Hello World'|t }}
{{ 'Hello @name'|t({'@name': user_name}) }}

{% trans %}
  You have 1 item.
{% plural count %}
  You have {{ count }} items.
{% endtrans %}
```

### Attributes Object

```twig
<div{{ attributes }}></div>
<div{{ attributes.addClass('my-class') }}></div>
<div{{ attributes.setAttribute('data-id', item.id) }}></div>
```

### Link Generation

```twig
{{ link(title, url) }}
<a href="{{ path('route.name', {'id': item.id}) }}">{{ title }}</a>
<a href="{{ url('route.name', {'id': item.id}) }}">{{ title }}</a>
```

### Attach Libraries

```twig
{{ attach_library('my_module/my_library') }}
```

---

## 8. Template Inheritance

Extend a template of the theme or its base theme by namespace and override only the blocks that change:

```twig
{# node--article.html.twig #}
{% extends '@my_theme/node.html.twig' %}

{% block content %}
  <div class="article__lead">{{ content.field_lead }}</div>
  {{ parent() }}
{% endblock %}
```

The parent template declares the blocks:

```twig
<article{{ attributes }}>
  {% block content %}
    {{ content }}
  {% endblock %}
</article>
```

---

## 9. Components and Includes

### Single Directory Components

Reusable UI lives in Single Directory Components (core since Drupal 10.3): one folder per component under
`components/` of a theme or module, holding `<name>.component.yml` (props and slots), `<name>.twig` and optional
`<name>.css` / `<name>.js`, which Drupal attaches automatically.

```yaml
# components/card/card.component.yml
name: Card
props:
  type: object
  required:
    - title
  properties:
    title:
      type: string
    featured:
      type: boolean
slots:
  body:
    title: Body
```

```twig
{# Props only. #}
{{ include('my_theme:card', {title: item.title, featured: item.is_featured}, with_context = false) }}

{# Props and slots. #}
{% embed 'my_theme:card' with {title: item.title} only %}
  {% block body %}
    {{ content.field_body }}
  {% endblock %}
{% endembed %}
```

Look for an existing component before writing markup; paragraph and field templates call components instead of
repeating their HTML.

### Plain Includes

A project without SDC includes partial templates by theme namespace and passes only what the partial needs:

```twig
{% include '@my_theme/partials/card.html.twig' with {
  title: item.title,
  image: item.image,
} only %}
```

---

## 10. BEM CSS Naming

```twig
<div class="card">                            {# Block #}
  <div class="card__header">                  {# Element #}
    <h2 class="card__title">{{ title }}</h2>
  </div>
  <div class="card__footer">
    <button class="card__button card__button--primary">{{ 'Action'|t }}</button> {# Modifier #}
  </div>
</div>

{# Dynamic classes #}
{%
  set classes = [
    'card',
    is_featured ? 'card--featured',
  ]
%}
<div{{ attributes.addClass(classes) }}></div>
```

---

## 11. Preprocessing

Always prepare data in PHP, not in templates. OOP preprocess hooks need Drupal 11.2+; on 11.1 and 10.x write the
same logic as a procedural `my_module_preprocess_my_template()` in `my_module.module`. A theme writes it as
`my_theme_preprocess_my_template()` in `my_theme.theme` up to Drupal 11.2, and as a `#[Hook]` class in the theme's
own `src/Hook/` from 11.3:

```php
<?php

declare(strict_types=1);

namespace Drupal\my_module\Hook;

use Drupal\Core\Hook\Attribute\Hook;

/**
 * Preprocess hook implementations for my_module.
 */
final class PreprocessHooks {

  /**
   * Implements hook_preprocess_HOOK() for my_template.
   */
  #[Hook('preprocess_my_template')]
  public function preprocessMyTemplate(array &$variables): void {
    $node = $variables['node'] ?? NULL;
    if ($node) {
      $variables['title'] = $node->getTitle();
      $variables['is_published'] = $node->isPublished();
      $variables['#attached']['library'][] = 'my_module/my_library';
    }
  }

}
```

---

## 12. Rendering Fields

```twig
{{ content }}
{{ content.field_body }}

{% if content.field_body|render|trim %}
  <div class="body">{{ content.field_body }}</div>
{% endif %}

<article{{ attributes }}>
  {{ content.field_image }}
  {{ content|without('field_image') }}
</article>
```

Render arrays carry cache metadata (tags, contexts, max-age). A template that prints single fields still prints
the rest with `{{ content|without(…) }}`, so that metadata reaches the page; raw values read from the entity
(`node.field_x.value`) bypass it.

---

## 13. Security

```twig
{# ✅ SAFE: Auto-escaped #}
{{ user_name }}
{{ form.element }}
{{ content }}

{# ⚠️ CAUTION: Only for pre-escaped content #}
{{ html_content|raw }}

{# ❌ NEVER: Dynamic HTML generation #}
{{ ('<span>' ~ title ~ '</span>')|raw }}
```

---

## 14. Performance

```twig
{# Render a part only when it is shown #}
{% if should_show_sidebar %}
  {{ include('my_theme:sidebar', {items: sidebar_items}, with_context = false) }}
{% endif %}

{# ❌ Filtering in a template #}
{% for item in items %}
  {% if item.status == 'active' and item.user.role == 'admin' %}
    <li>{{ item.title }}</li>
  {% endif %}
{% endfor %}

{# ✅ Filtered in PHP preprocess #}
{% for item in filtered_items %}
  <li>{{ item.title }}</li>
{% endfor %}
```

---

## 15. Debugging

`dump()` works when Twig debug is on (`/admin/config/development/settings` or `twig.config: debug: true` in
`development.services.yml`). Remove it before committing.

```twig
{{ dump() }}
{{ dump(my_variable) }}

{# List available variables #}
{{ dump(_context|keys) }}
```

---

## 16. Common Gotchas

### Undefined Variables

Drupal runs Twig with `strict_variables` off: an undefined variable prints nothing and raises no error, so a typo
in a variable name fails silently. Give optional variables a default or test them:

```twig
{{ my_var|default('No value'|t) }}

{% if my_var is defined and my_var is not empty %}
  {{ my_var }}
{% endif %}
```

### Empty Render Arrays

`{% if content.field_x %}` is true for a field that renders nothing, because the render array itself is not empty.
Test the rendered output — `{% if content.field_x|render|trim %}` — or pass a boolean from preprocess.

### Loop Variable Scope

```twig
{# The loop variable exists only inside the loop #}
{% for item in items %}{{ loop.index }}{% endfor %}

{# Values needed outside the loop are set outside #}
{% set item_count = items|length %}
```

---

## 17. Quick Reference Checklist

- [ ] All templates have file header documentation
- [ ] All variables are documented
- [ ] Output is auto-escaped (only `|raw` for safe content)
- [ ] No business logic in templates
- [ ] Existing component reused before new markup is written
- [ ] Semantic HTML used
- [ ] BEM class naming
- [ ] Data processed in preprocess functions
- [ ] Cache metadata preserved (`content` or `content|without(…)` is printed)
- [ ] Strings translated with `|t` / `{% trans %}`
- [ ] ARIA labels where needed
- [ ] 2-space indentation, no space before `(`
