---
name: drupal-performance-review
description: Review Drupal code for performance issues (queries, caching, rendering)
argument-hint: <file, directory or route>
---

Review the performance of: $ARGUMENTS

Read the code first — every file in scope plus the services it calls — then walk the checklist. A finding needs
evidence: the line that causes it and the mechanism ("one `load()` per item in the loop at line 42"). Numbers
appear only when you measured them; an unmeasured impact is described, never estimated.

## Checklist

### Database

- A query or entity load inside a loop (N+1): replace with `loadMultiple()` or one query.
- `->fields('alias')` selecting every column when a few are used.
- Conditions or sorts on columns without an index (`hook_schema()` / entity field storage).
- Entity queries or selects without `range()` on tables that grow.
- Inserts or updates row by row where one multi-row statement or the Batch/Queue API fits.

### Caching

- Render arrays without `#cache` — tags, contexts and max-age all considered.
- Contexts that are too broad (`user` where `user.roles` or `user.permissions` is enough) or missing (output
  varies by something that is not declared).
- `max-age: 0` or `\Drupal::service('page_cache_kill_switch')` disabling the page cache for a whole page;
  `#lazy_builder` isolates the dynamic part instead.
- Expensive computation repeated per request without a cache bin, or cached without tags to invalidate it.
- Cache metadata lost on the way: fields printed one by one in Twig without rendering `content`, access results
  without `addCacheableDependency()`.

### Entities and rendering

- Entities loaded only to read one value that a query could return.
- Reference chains walked item by item (`$node->field_x->entity->field_y->entity`) inside lists.
- Full entities rendered where a view mode with fewer fields fits.
- Logic or loads in Twig or preprocess that run per item of a long list.
- Libraries attached globally that only one component needs.

### Memory and long work

- Unbounded result sets loaded at once; process in chunks or with a generator.
- Work that belongs in a queue or batch running inside a web request or `hook_cron()`.

### External calls

- HTTP requests without `timeout` and `connect_timeout`.
- The same endpoint requested repeatedly without caching the response.
- A blocking call in a page request that a queue worker could make.

### Config and state

- `$this->configFactory->get()` inside a loop for the same object.
- Frequently changing values stored in config (belongs in state) — every save invalidates the config's cache
  tags and turns into config drift on export.

## Measuring

Measure when the user asks for numbers or a finding's size is unclear:

```bash
ddev drush php:eval '<code that runs the path>'           # with a query logger: Database::startLog('review')
ddev exec curl -sk -o /dev/null -w '%{time_total}\n' https://<project>.ddev.site/<path>
ddev drush sql:query 'EXPLAIN <query>'
```

`X-Drupal-Cache` and `X-Drupal-Dynamic-Cache` response headers show whether a page is cached and why not.

## Report

Findings ordered by severity, each with:

- **Severity** — critical (grows with data or traffic), major, minor;
- **Location** — `file:line`;
- **Problem** — the mechanism;
- **Fix** — the concrete change, with code when it is short.

End with the checklist areas that had no findings, so the reader knows they were checked. Apply fixes only when
the user asked for them.
