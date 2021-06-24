---
title: "Phoenix + Tailwind + Docker issues"
date: 2021-06-21T22:37:58-04:00
keywords: "elixir,tailwind,docker"
categories:
- Elixir
- Phoenix
tags:
- Elixir
- Phoenix
- Tailwind
draft: false
---

## The Problem
I was having issues with tailwind building correctly **ONLY** in production and **ONLY** when built in a Docker container.

I followed an [online guide](https://s2g.io/using-tailwindcss-with-phoenix) to get postcss and tailwind configured correctly so that it only builds the classes required by the application (we don't want a huge css file). My tailwind.config.js looked like this:
```javascript
module.exports = {
  purge: [
    '../lib/**/*.ex',
    '../lib/**/*.leex',
    '../lib/**/*.eex',
    './js/**/*.js'
  ],
  enabled: process.env.NODE_ENV === 'production',
  mode: 'jit',
  darkMode: false, // or 'media' or 'class'
  theme: {
    extend: {
      container: (theme) => ({
        center: true,
        padding: theme("spacing.4"),
        screens: {
          sm: "100%",
          md: "100%",
          lg: "1024px",
          xl: "1280px"
       }
      })
    },
  },
  variants: {
    extend: {},
  },
  plugins: [
    require('@tailwindcss/typography'),
  ],
}
```
Here we are telling tailwind to search through our `.ex`, `.leex`, `.eex` and `.js` files for relevent classes and purge anything not used.

This all worked perfect in development and local testing.

I add a Dockerfile to use as my production deployment stategy. I started with the [Phoenix documented](https://hexdocs.pm/phoenix/releases.html#containers) version of the Dockerfile and tweaked it a little to use the latest version of Elixir. Here is what I ended up with that was not compiling tailwind correctly:
```Dockerfile
FROM elixir:1.12.1-alpine AS build

RUN apk add --no-cache build-base npm git python3

WORKDIR /app

RUN mix local.hex --force && \
    mix local.rebar --force

ENV MIX_ENV=prod

COPY mix.exs mix.lock ./
COPY config config
RUN mix do deps.get, deps.compile

# build assets
COPY assets/package.json assets/package-lock.json ./assets/
RUN npm --prefix ./assets ci --progress=false --no-audit --loglevel=error

COPY priv priv
COPY assets assets

RUN npm run --prefix ./assets deploy
RUN mix phx.digest

COPY lib lib
# uncomment COPY if rel/ exists
# COPY rel rel
RUN mix do compile, release

# prepare release image
FROM alpine:3.13 AS app
RUN apk add --no-cache openssl ncurses-libs libstdc++

WORKDIR /app

RUN chown nobody:nobody /app

USER nobody:nobody

COPY --from=build --chown=nobody:nobody /app/_build/prod/rel/my_app ./

ENV HOME=/app

CMD trap 'exit' INT; ./bin/my_app eval "MyApp.Release.migrate()" && ./bin/my_app start
```

## The Solution

I tried many different things to fix the issue. I tried installing a specific version of node in the image - building a development build with webpack - but what it came down to was an order of operations bug.

Remember the tailwind config from above? It says to purge any tailwind classes that haven't been used in our template files. Well, our image doesn't have any template files at the time of running `npm run --prefix ./assets deploy` because we haven't copied our `lib` folder over to the image yet!

So the simple fix was to move `COPY lib lib` up in the Dockerfile before running `npm deploy`.
