# Trigger Code

This folder holds every runnable SQL example from the parent tutorial
`MySQL-Triggers.md`, **split into one `.sql` file per example**.

## Layout

```
trigger/
├── 00-setup.sql                       # Canonical schema + seed data
├── README.md                          # this file
├── run-all.sh                         # run every file end-to-end
├── 01-introduction/                   # concepts only — no SQL
├── 02-managing-triggers/
│   ├── setup-02-01-creating-a-trigger.sql
│   ├── setup-02-02-dropping-a-trigger.sql
│   └── example-02-01-01-strip-whitespace-on-insert.sql
├── 03-before-insert/
│   ├── example-03-01-01-update-stock-summary.sql
│   └── example-03-01-02-clean-and-reject-negative-price.sql
├── 04-after-insert/
│   ├── setup-04-01-book-reviews-table.sql
│   └── example-04-01-01-auto-create-placeholder-review.sql
├── 05-before-update/
│   ├── example-05-01-01-reject-bad-price-and-stock.sql
│   └── example-05-01-02-clamp-price-no-more-than-half-off.sql
├── 06-after-update/
│   └── example-06-01-01-log-only-when-price-changes.sql
├── 07-before-delete/
│   ├── example-07-01-01-block-delete-while-in-stock.sql
│   └── example-07-01-02-copy-row-to-archive-before-delete.sql
├── 08-after-delete/
│   ├── example-08-01-01-archive-row-on-delete.sql
│   └── example-08-01-02-archive-and-log-deletion.sql
├── 09-multiple-triggers/
│   ├── setup-09-01-book-notifications-table.sql
│   └── example-09-01-01-two-after-insert-triggers-with-follows.sql
└── 10-show-triggers/
    ├── example-10-01-01-list-triggers-show-and-information-schema.sql
    └── example-10-01-02-show-create-trigger.sql
```

File naming:

- **`setup-NN-MM-…sql`** — small schema or syntax demo that follows a `## N.M` sub-section.
- **`example-NN-MM-KK-…sql`** — a single, self-contained runnable example.

## Quick start

```bash
# 1. Create the schema + seed data
mysql -u root -p < 00-setup.sql

# 2. Run any example directly
mysql -u root -p < 02-managing-triggers/example-02-01-01-strip-whitespace-on-insert.sql

# 3. Or run everything in order
./run-all.sh
```

> The scripts are written to be fed directly to `mysql` — the original
> markdown's `DELIMITER $$` markers are stripped, so each file is parsed as a
> single SQL statement stream. Triggers don't need a custom delimiter anyway
> because the `mysql` client recognises `CREATE TRIGGER ... END;` natively.

## Section 1 — concepts only

`01-introduction/` contains a short README and **no SQL**, because Section 1
of the tutorial only explains what a trigger is and the 6 possible
`BEFORE/AFTER × INSERT/UPDATE/DELETE` shapes. Move on to
`02-managing-triggers/` for the first `CREATE TRIGGER` example.