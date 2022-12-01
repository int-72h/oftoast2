# OFTOAST II (oftoast-godot)

Rewritten from the ground up with many changes to make life easier for the end users and for the maintainers.
- Autoupdating, like some sorta fancy electron app
- [download-from-zip](https://kmatter.net/posts/tvn-the-strong-stuff/) functionality
- Sentry integration (hopefully)
- Ability to specify the path without it exploding
- Shouldn't be flagged as a virus
- Looks a lot nicer ~~(objectively)~~
- Blog panel (thanks pyspy)
- Uses a stable (enough) libcurl backend
- More graceful error handling (hopefully)
- Many more things I've probably forgot.


## Building
You're going to need [this gdnative extension](https://github.com/toastware/oftoast2-gdnative), place it in ``gdnative/[platform]/`` and hopefully it should work. I'll eventually get CI working.
