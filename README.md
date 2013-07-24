buildr-kawa
===========

Clone of upstream buildr repo (non-Github unfortunately) with my Kawa support additions for mixed mode (java+kawa) compilation

Since the docs on the buildr homepage regarding building is obsolete, here's how to build buildr:

    bundle install
    rake gem
    sudo gem install pkg/buildr-1.4.13.dev.gem

Modify the last line if you're on another platform, although please note that the current kawa support
has not been written to support, or have been tested, on any other platform than linux.
