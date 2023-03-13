# OFTOAST II (oftoast-godot)

Rewritten from the ground up with many changes to make life easier for the end users and for the maintainers.
- Autoupdating
- [download-from-zip](https://kmatter.net/posts/tvn-the-strong-stuff/) functionality
- Improved UI functionality, with shiny animations
- Blog panel (Thanks to PySpy for some of the code)
- Uses Libcurl via the GDNative extension
- More graceful error handling


## Building
You're going to need [this gdnative extension](https://github.com/toastware/oftoast2-gdnative), place it in ``gdnative/[platform]/`` and hopefully it should work.

CI is working, builds are available for Windows and Linux.
