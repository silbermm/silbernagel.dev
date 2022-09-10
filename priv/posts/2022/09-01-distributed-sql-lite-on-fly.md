%{
  title: "Distributed SQLite on Fly.io",
  author: "Matt Silbernagel",
  tags: ~w(Elixir Phoenix SQLite),
  description: "Phoenix with SQLite as a Distributed Database at the edge with Fly.io",
  draft: true
}
---

## TLDR;

## What
I recently read about [lightstream](https://litestream.io/) and wanted to try this on [Fly](https://fly.io).

## Why
* **fast** data access
* using elixir's distribution capabilitys to make data eventually consistent

## Getting Started
Create a new phoenix app that uses [SQLite3]() as it's database:
```bash
$ mix phx.new distributed_sqlite --database sqlite3
```

Lets try to push this up to Fly as-is and see what happens:

```bash
$ fly launch
```
* type in an app name (or just take the default)
* choose any region you like
* choose N when asked if you want a Postgres database
* choose Y to deploy now

The deploy should fail becuase we need to define a few environment variables. First, we need specify a `DATABASE_FILE` so ecto knows where the sqlite db file is.
```bash
$ 
```



## Distributing


## Wrap Up


