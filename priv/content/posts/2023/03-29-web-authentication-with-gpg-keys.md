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

The concept here is pretty simple.

### A user wants to register for the site. 
1. They provide their email that is their uid of there GPG key
2. We try to find their public key via [WKD](https://wiki.gnupg.org/WKD) or some well known key servers
    1. If we can't find a key, provide a way to upload their public key
3. Import the users public key into the systems GPG store
4. Email the user a randomly generated large string for them to sign with their key. I like this over just providing it to them on the web page because it at least proves they actually own the email that is attached to the key.
5. Have the user input the signed text and verify it against the original text.
6. If it all checks out, activate their account

### A registered user wants to login




