### Hooks
- **Hook implementation**: On Drupal 11.1+ use OOP hooks — `#[Hook('...')]` methods on a class in `src/Hook/`; on Drupal 10.x implement them in `modulename.module`
- **Install-time hooks**: `hook_install()`, `hook_uninstall()`, `hook_update_N()`, `hook_schema()`, `hook_requirements()` cannot be OOP hooks and must stay procedural in the `.install`/`.module` file
- **Hook parameters**: Use type hints and proper parameter documentation; keep canonical names for inherited signatures (`$form_state`, `$form_id`)
- **Core hooks**: Common hooks include `hook_form_alter()`, `hook_theme()`, `hook_menu_links_discovered_alter()`
- **Hook order**: Hooks fire in module weight order (lowest first)
- **Best practice**: Keep hook implementations focused and use services for complex logic
