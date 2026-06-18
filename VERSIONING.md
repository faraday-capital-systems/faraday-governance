# Versioning

Governance releases use immutable `vMAJOR.MINOR.PATCH` tags.

Products pin a released tag, never `main`. Released tags are immutable: do not
move, delete, or rewrite a tag after publication.

Bundle hash command:

```bash
git archive <tag> | sha256sum
```

A product must fail closed if its pinned tag or bundle hash cannot be verified.
