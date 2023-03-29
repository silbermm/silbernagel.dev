%{
  title: "Web Authentication with GPG keys",
  author: "Matt Silbernagel",
  tags: ~w(gpg phoenix elixir),
  description: "Building an authentication system using GPG keys and the Phoenix framework.",
  draft: true
}
---

Ever wanted to find more uses for your GPG keys? No, probably not.

Maintaining your GPG keys can be tedious and the tooling for them is not what I'd call 'user friendly'.

But they are a great tool for helping prove your identity, and they are great for securly sharing data.

To that end, I wanted to try an experiment that uses GPG public keys to authenticate users to a website. I think I came up with a pretty good solution, but it still could benefit from a better user experience.

## Overview

