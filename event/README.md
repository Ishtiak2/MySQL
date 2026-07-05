# Event Code

This folder holds every runnable SQL example from the parent tutorial
`MySQL-Events.md`, **split into one `.sql` file per example**.

## Layout

```
event/
├── 00-setup.sql                         # Canonical schema + seed data
├── README.md                            # this file
├── run-all.sh                           # run every file end-to-end
├── 01-introduction/                     # concepts only — no SQL
├── 02-create-event/
│   ├── example-02-01-01-hello-world-one-time-event.sql
│   ├── example-02-02-01-every-minute-refresh-summary.sql
│   ├── example-02-03-01-daily-at-3am-archive-old-orders.sql
│   ├── example-02-04-01-starts-and-ends-two-hour-window.sql
│   └── example-02-05-01-keep-after-fire-on-completion-preserve.sql
├── 03-alter-event/
│   ├── example-03-01-01-disable-an-event.sql
│   ├── example-03-02-01-enable-an-event.sql
│   ├── example-03-03-01-change-schedule-and-body.sql
│   └── example-03-04-01-rename-via-drop-and-recreate.sql
├── 04-drop-event/
│   ├── example-04-01-01-drop-an-event.sql
│   └── example-04-02-01-drop-event-if-exists.sql
└── 05-show-events/
    ├── example-05-01-01-show-events-current-database.sql
    ├── example-05-02-01-show-events-from-database.sql
    ├── example-05-03-01-show-events-like-pattern.sql
    ├── example-05-04-01-show-events-where-status.sql
    ├── example-05-05-01-information-schema-events.sql
    └── example-05-06-01-show-create-event.sql
```

File naming:

- **`setup-NN-MM-…sql`** — small schema or syntax demo that follows a `## N.M` sub-section.
- **`example-NN-MM-KK-…sql`** — a single, self-contained runnable example.

## Quick start

```bash
# 0. Make sure the event scheduler is ON — events are stored but never run
#    while it is OFF.
mysql -u root -p -e "SET GLOBAL event_scheduler = ON;"

# 1. Create the schema + seed data
mysql -u root -p < 00-setup.sql

# 2. Run any example directly
mysql -u root -p < 02-create-event/example-02-01-01-hello-world-one-time-event.sql

# 3. Or run everything in order
./run-all.sh
```

> The scripts are written to be fed directly to `mysql` — each file is parsed
> as a single SQL statement stream. Events don't need a custom delimiter
> either, because the `mysql` client recognises `CREATE EVENT ... DO ...;`
> natively.

## A note on time

A handful of the `02-create-event/` examples are deliberately short so they
fire on a "human" timescale (e.g. "30 seconds from now"). After running them:

```sql
USE event_demo;
SELECT * FROM event_log ORDER BY id DESC;
SHOW EVENTS;
```

…to see the event body, the rows it wrote, and the schedule it is on. For
recurring events that fire every minute, give the scheduler a minute or two
between running the example and checking `event_log`.

## Section 1 — concepts only

`01-introduction/` contains a short README and **no SQL**, because Section 1
of the tutorial only explains what an event is, the scheduler on/off switch,
and the anatomy of a `CREATE EVENT` statement. Move on to
`02-create-event/` for the first runnable example.