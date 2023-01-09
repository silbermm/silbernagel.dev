%{
  title: "Distributed SQLite with Elixir",
  author: "Matt Silbernagel",
  tags: ~w(Elixir Phoenix SQLite),
  description: "Phoenix with SQLite as a Distributed Database at the edge",
  draft: true
}
---

I recently read about [litestream](https://litestream.io/) and wanted to try this on [Fly](https://fly.io) with [Elixir](https://elixir-lang.org/).

[Litestream](https://litestream.io/) allows us to backup our SQLite database to any S3 compatible storage after every transaction. It will also restore from that backup. Meaning that anytime we scale our app on Fly, we can restore the latest version of the database. 

## Why
* **fast** data access
* **simple** local development
* **low** maintenance
* Elixir makes it possible via it's distribution capabilities

## Getting Started
Create a new phoenix app that uses [SQLite3](https://github.com/elixir-sqlite/ecto_sqlite3) as the database:
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

We'll need to add an environment variable to indicate which file to use for the SQLite database.

Open the `fly.toml` file and add `DATABASE_PATH = /data/distributed_sqlite.db` under the `[env]` section.

Let's try to deploy now
```bash
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

## Counter Data Model

Lets build a simple, naive counter that just counts the views of each page.

```bash
$ mix phx.gen.schema Counter.PageCount page_counts page:string count:integer
$ mix ecto.migrate
```

Now we can add a `Counter` module that will add page view counts

```elixir
# lib/distributed_sqlite/counter.ex
defmodule DistributedSqlite.Counter do
  alias DistributedSqlite.Counter.PageCount
  alias DistributedSqlite.Repo

  def count_page_view(page_name) do
    page_count = Repo.get_by(PageCount, page: page_name) || %PageCount{page: page_name, count: 0}

    page_count
    |> PageCount.changeset(%{count: page_count.count + 1})
    |> Repo.insert_or_update!()
  end
end
```

and update the page_controller to count views
```elixir
  # lib/distributed_sqlite_web/controllers/page_controller.ex
  alias DistributedSqlite.Counter

  def index(conn, _params) do
    page_view = Counter.count_page_view("home")
    render(conn, "index.html", page_count: page_view.count)
  end
```

lastly, we can display the counter on our page

```eex
<!-- lib/distributed_sqlite_web/templates/page/index.html.heex -->
<h1> Page Views <%= @view_count %> </h1>
```

Now deploy again using `flyctl deploy` and then browse to your site to validate that the count is showing and updating when refreshing.

## Restoring the Database on Deploy

The next problem to deal with that the database will be wiped on our next deploy since it's using ephemeral storage.

One way to resolve this is to use a persistent volume (which is probably not a bad idea for production apps). But since this post is all about [litestream](https://litestream.io/) lets set that up and see how it helps us here.

The first step is to create a bucket in some S3 compatible storage. I like to use [Digital Ocean spaces](https://www.digitalocean.com/products/spaces) for this, but you can also use AWS if you want. [See litestream docs for more options](https://litestream.io/guides/)

You'll need 3 things:
1. the bucket url
2. the access key
3. the secret key


Next, add litestream to our Docker image. Add the following lines to `Dockerfile` as part of the `builder` phase:
```
ADD https://github.com/benbjohnson/litestream/releases/download/v0.3.9/litestream-v0.3.9-linux-amd64-static.tar.gz /tmp/litestream.tar.gz
RUN tar -C /usr/local/bin -xzf /tmp/litestream.tar.gz
```

And in the `runner` phase add:
```
COPY --from=builder /usr/local/bin/litestream /usr/local/bin/litestream
COPY litestream.yml /etc/litestream.yml
```

We still need to create the `litestream.yml` file, lets do that now.

```
access-key-id: ${LITESTREAM_ACCESS_KEY_ID}
secret-access-key: ${LITESTREAM_SECRET_ACCESS_KEY}

dbs:
  - path: /data/distributed_sql.db
    replicas:
      - url: ${REPLICA_URL}
```

Now set the three variables in Fly to the values you recorded from when setting up the bucket.

```
$ flyctl secrets set REPLICA_URL=... LITESTREAM_ACCESS_KEY_ID=... LITESTREAM_SECRET_ACCESS_KEY=...
```

Finally, we need to update how we start our app so that it's a sub-process of litestream. The easiest way I've found to do this is to create a run script called `run.sh` with the following content:
```
#!/bin/bash
set -e

# Restore the database if it does not already exist.
if [ -f /data/distributed_sql.db ]; then
  echo "Database already exists, skipping restore"
else
  echo "No database found, restoring from replica if exists"
  litestream restore -v -if-replica-exists -o /data/distributed_sql.db "${REPLICA_URL}"
fi

# Run migrations
/app/bin/migrate

# Run litestream with your app as the subprocess.
exec litestream replicate -exec "/app/bin/server"
```

> Be sure to remove the migration script from fly.toml since we are doing it in a different step now

Now update the `Dockerfile` to use this new script to start the app:

```
COPY run.sh /scripts/run.sh
RUN chmod 777 /scripts/run.sh

CMD ["/scripts/run.sh"]
```

Deploying should now start using litestream restore the database on deploys and push backups when data changes. You can verify in the monitoring interface of fly. Look for something similar to the image below:

![Fly logs showing that litestream is running](/images/fly-logs.png "Fly Logs")

## Distributing

With all of this in place, things would work great if you only wanted to run one instance of you app. But as soon as you add another node things get out of wack. 

Lets see this in action -- Scale the app to 2 and see what happens to the data.

```
$ flyctl scale count 2
```

Enough refreshing or opening in different browser sessions and you'll start to see discrepencies in the view count. This is because we are replicating the data between the instances. But we have Elixir and this shouldn't be to hard to do.

Follow the [Fly guide to Clustering Your Application](https://fly.io/docs/elixir/getting-started/clustering/) to get clustering working correctly.

Once your app is clustered, we can begin to replicate our database calls. Add a new GenServer with the following content:
```elixir
# /lib/distributed_sqlite/repo_replication.ex
defmodule DistributedSqlite.RepoReplication do
  @moduledoc """
  Run on each node to handle replicating Repo writes
  """
  use GenServer

  alias DistributedSqlite.Repo

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  @impl true
  def init(_args) do
    {:ok, []}
  end

  @impl true
  def handle_cast({:replicate, func}, state) when is_function(func) do
    func.()
    {:noreply, state}
  end

  def handle_cast({:replicate, query, :insert}, state) do
    Repo.insert!(query)
    {:noreply, state}
  end

  def handle_cast({:replicate, changeset, :update}, state) do
    Repo.update!(changeset)
    {:noreply, state}
  end
end
```

and make sure to start it in the `application.ex` 

```elixir
# lib/distributed_sqlite/application.ex
children = [
  ...,
  {DistributedSqlite.RepoReplication, []}
]
```



## Wrap Up


