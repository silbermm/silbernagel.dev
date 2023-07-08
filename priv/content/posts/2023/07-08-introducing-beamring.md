%{
  title: "Introducing Beamring",
  author: "Matt Silbernagel",
  tags: ~w(elixir, indieweb),
  description: "A new webring for the BEAM community.",
  draft: false
}
---

Today I released a new project, [Beamring](https://beamring.io). It's a simple implementation of a [webring](https://en.wikipedia.org/wiki/Webring) built on the BEAM and for the BEAM community.

The source code can be [found on github](https://github.com/silbermm/beamring).

## Why?

Before there were the big social media networks, discovery on the web was hard. Webrings were formed as a way to link similar content sites together and provided a way for people to find the content they wanted.

As the walled gardens (facebook, twitter and reddit) are falling apart, the [indieweb](https://indieweb.org/) has a chance to flourish and webrings could prove to be useful once again. 

Plus, it's fun to build small projects with a singular focus.

## Can my site be added?

I'm glad you asked!

If you have a site that you feel should be added to beamring, there are two steps to take.

1. First you'll need to add a small code snippet to your site, something similar to the following:
```html
<div>
    <p>
        <a href="https://beamring.io/previous?host=https://yoursite.com">←</a>
        <a href="https://beamring.io">Beamring</a>
        <a href="https://beamring.io/next?host=https://yoursite.com">→</a>
    </p>
</div>
```
This is what makes the webring work. Each site does this and the links will redirect the visitor to the next or previous site in the ring.

2. Fill out [this github issue](https://github.com/silbermm/beamring/issues/new?assignees=silbermm&labels=new&projects=&template=add_site.yml&title=%5BAdd%5D%3A+) with your sites information. Once I've validated that the markup is on your site and your site is somehow related to the BEAM, you'll be added.

## Whats Next

I don't have much else planned for this tiny project, but am always happy to take feature requests on [github](https://github.com/silbermm/beamring/issues).

Go forth and explore the [indieweb](https://indieweb.org/Getting_Started)

[](https://fed.brid.gy/)
