### Plugin System
- **Plugin types**: Blocks, field formatters, field widgets, menu links, and more
- **Plugin discovery**: Use PHP attribute-based discovery (e.g. `#[Block(...)]`, `#[FieldFormatter(...)]`) placed directly above the class at column 0. Annotations in docblocks are the legacy alternative
- **Plugin configuration**: Define plugin ID, label, and other metadata in the attribute arguments (use `TranslatableMarkup` for labels)
- **Plugin base classes**: Extend appropriate base classes (BlockBase, FormatterBase, etc.)
- **Plugin placement**: Place plugins in `src/Plugin/Type/` directory structure
- **Derivative plugins**: Use for creating multiple plugins from one definition
