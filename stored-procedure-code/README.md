# Stored Procedure Code

This folder holds every runnable SQL example from the parent tutorial
`MySQL-Stored-Procedures.md`, **split into one `.sql` file per example**.

## Layout

```
stored-procedure-code/
├── 00-setup.sql                       # Canonical schema + seed data
├── README.md                          # this file
├── run-all.sh                         # run every file end-to-end
├── 01-basic-stored-procedures/
│   ├── setup-01-01-…-introduction-to-mysql-stored-procedures.sql
│   ├── …
│   └── setup-01-08-…-listing-stored-procedures.sql
├── 02-conditional-statements/
│   ├── setup-02-01-the-if-statement.sql
│   ├── setup-02-02-the-case-statement.sql
│   ├── example-02-01-01-simple-if-else.sql
│   ├── example-02-01-02-one-liner-if-without-elseif.sql
│   ├── example-02-02-01-simple-case-compare-one-value.sql
│   └── example-02-02-02-searched-case-compare-conditions.sql
├── 03-loops/                          # WHILE / REPEAT / LOOP examples
├── 04-error-handling/                 # HANDLER / CONDITION / SIGNAL / RESIGNAL
├── 05-cursors-prepared-statements/    # Cursors + PREPARE/EXECUTE
├── 06-stored-functions/               # CREATE/DROP FUNCTION
├── 07-stored-program-security/        # DEFINER / SQL SECURITY / GRANT EXECUTE
└── 08-transactions/                   # START TRANSACTION / SAVEPOINT / ROLLBACK
```

File naming:

- **`setup-NN-MM-…sql`** — schema / syntax demos that follow the `## N.M` sub-section.
- **`example-NN-MM-KK-…sql`** — a single, self-contained runnable example.

## Quick start

```bash
# 1. Create the schema + seed data
mysql -u root -p < 00-setup.sql

# 2. Run any example directly
mysql -u root -p < 02-conditional-statements/example-02-01-01-simple-if-else.sql

# 3. Or run everything in order
./run-all.sh
```

> The scripts are written to be fed directly to `mysql` — the original
> markdown's `DELIMITER $$` markers are stripped, so each file is parsed as a
> single SQL statement stream.

## Re-generating from the markdown

The split was produced by parsing `../MySQL-Stored-Procedures.md` and
emitting one file per `### Example N.M.K` heading and per `## N.M`
sub-section that contains a runnable `sql` block. To rebuild, run the
small Python pass at the end of the conversation that produced this
folder — it lives in the chat log; nothing is checked in here.
