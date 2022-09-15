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
* choose N to deploy now

We need to define a few environment variables for our first deployment to be successful. First, we need define a `DATABASE_PATH` so ecto knows where the sqlite db file is.
```bash
$ flyctl secrets set DATABASE_PATH=/data/distributed_sqlite.db
```
You can use any file name you like, I just choose to name it the same as my application `distributed_sqlite`

Let's try to deploy now
```bash
$ flyctl deploy
```

It failed for me because I'm missing a `SECRET_KEY_BASE` environment variable, so lets create that and deploy again.
```bash
$ mix phx.gen.secret 
$ flyctl secrets set SECRET_KEY_BASE={output from above command}
$ flyctl deploy
```

Another failure. This time it's because I am using directory that doesn't exist yet in `/data`. This is an easy fix. In the `Dockerfile` I just add:
```
# Storage for the database
RUN mkdir -p /data
RUN chown nobody /data
```

and try to deploy again
```bash
$ flyctl deploy
```

Success! A Phoenix app running on Fly using SQLite! 

Lets build a simple data model so we can see our DB working.

## Counter

## Distributing


## Wrap Up


