buildr-kawa
===========

Clone of upstream buildr repo (non-Github unfortunately) with my Kawa support additions for mixed mode (java+kawa) compilation

Since the docs on the buildr homepage regarding building is obsolete, here's how to build buildr:

    bundle install
    rake gem
    sudo gem install pkg/buildr-1.4.13.dev.gem

If you get an error on even the first line, it means you haven't gotten a proper Ruby environment install. On Ubuntu, try `sudo apt-get install ruby-dev` and then `gem install bundler` before executing the commands above.

Modify the last line if you're on another platform, although please note that the current kawa support
has not been written to support, or have been tested, on any other platform than linux.

To run the kawa tests, run the following command:

    rspec spec/kawa/compiler_spec.rb

If you're using java 1.7, you may have some issues related to 1.6/1.7 bytecode compatibility when building kawa. Here's what I'm using with Oracle Java 1.7:

    make distclean && JAVACFLAGS="-source 6 -target 6" ./configure --with-android=$ANDROID_HOME/platforms/$ANDROID_PLATFORM/android.jar --disable-xquery --disable-jemacs && make && make install

The ANDROID variables I'm using are:

    ANDROID_HOME="/opt/android-studio/sdk"
    ANDROID_PLATFORM="android-15"

They need to be adjusted to whatever they need to be on your systems (your SDK and target platform). This is adapted from Per Bothner's instructions for building on Kawa with Android support which you can find here http://www.gnu.org/software/kawa/Building-for-Android.html.


