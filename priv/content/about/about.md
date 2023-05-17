%{
  title: "About",
  author: "Matt Silbernagel",
  description: "About Silbernagel.dev",
  published: "2023-05-16",
  updated: "",
  draft: true
}
---
## Who Am I?

My name is Matt Silbernagel, I live in the United States, and I'm a Software Engineer happily writing [#Elixir](https://silbernagel.dev/tags/Elixir) for my day job and my hobby projects.

I use this [IndieWeb](https://indieweb.org/) site to write about technologies I'm exploring and lessons I've learned in hopes that I can help reduce barriers for anyone else struggling with similar problems or exploring similar ideas.

You can find me in the FediVerse at [@ahappydeath@freeradical.zone](https://freeradical.zone/@ahappydeath).

My GPG public key is available [on this site](/gpg) and via [WKD](https://wiki.gnupg.org/WKD#What_is_a_Web_Key_Directory.3F) 

---

## What I'm up to

Interests currently include:
* Elixir, Rust, and Zig
* Building local-first and decentralized software (**NOT** web3 or crypto)
* The IndieWeb

---

## My Setup

| 💻 Laptop | [System76 Lemur Pro](https://system76.com/laptops/lemur) |
| 🍥 OS     | [Pop!_OS](https://pop.system76.com/) (previously Arch)   |
| 🗒 Editor | [Neovim](https://neovim.io/)                             |
| 🐚 Shell  | [zsh](https://ohmyz.sh/) |
| 🖥 󠀾Terminal Emulator | [Alacritty](https://alacritty.org/)           |
| 📁 My dot files | [https://github.com/silbermm/dotfiles](https://github.com/silbermm/dotfiles) |

---

## How this site is built

This site is built with Elixir and Phoenix and can be found on [Github](https://github.com/silbermm/silbernagel.dev).

I use the [NimblePublisher](https://hexdocs.pm/nimble_publisher/NimblePublisher.html) library to generate static content like my [Posts](/posts) which are also syndicated in the fediverse at [@silbernagel.dev@silbernagel.dev](https://fed.brid.gy/user/silbernagel.dev) and via  [RSS](/posts/rss.xml).

Comments and likes are accepted via [WebMentions](https://www.w3.org/TR/webmention/#introduction) and are stored in a [distributed SQLite](/posts/distributed-sqlite-with-elixir) database which is hosted on fly.io alongside this site.
