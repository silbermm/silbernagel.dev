%{
  title: "Web Authentication with PGP keys",
  author: "Matt Silbernagel",
  tags: ~w(gpg phoenix elixir),
  description: "Building an authentication system using PGP keys and the Phoenix framework.",
  draft: true
}
---

Ever wanted to find more uses for your PGP keys? No, probably not.

Maintaining your PGP keys can be tedious and the tooling for them is not user friendly.

But they are a great tool for helping prove your identity, and securely sharing data.

To that end, I wanted to try an experiment that uses PGP public keys to authenticate users instead of the traditional username/password. I think I came up with a pretty good solution, but it still could benefit from a better user experience.

## Overview

The concept here is pretty simple.

### A user registers 
1. User provides their email that is the UID of their PGP key
2. We try to find their public key via [WKD](https://wiki.gnupg.org/WKD) or some well known key servers
    1. If we can't find a key, provide a way to upload their public key
3. Import the users public key into the systems PGP store
4. Email the user a randomly generated large string for them to sign with their private key. I like this over just providing it to them on the web page because it at least proves they actually own the email that is attached to the key.
5. Have the user input the signed text and verify it against the original text.
6. If it all checks out, activate their account

### A registered user logins

There are a few ways of handling this.

One easy way is to send a magic link via email. Theoretically we've vetted their email already, so this seems safe enough.

The less user friendly way is to provide another randomly generated string for the user to sign and then verify the signature, just like during registration.

The least friendly way is to provide another tool that runs locally on the users computer (like a CLI tool) that can programmatically reach out to the site, ask for a string to sign, sign it and get a magic link in return. Since a tool like this runs locally, it would be able to access PGP on the user's machine and would require little to no input from the user.

And the last method that doesn't yet seem possible is to access the users local PGP store from the browser. This feels insecure at best and I don't plan on pursuing it.

## Show me some code!

I'll be using Elixir and Phoenix for the samples, but this should be transferable to the language and framework of your choosing.


