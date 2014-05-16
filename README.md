SpinalTapCodeMosh
=================

Yet another code-pastebin app; Powered by Dancer using the power of Backbone
for the UI.

Still has some bugs and missing features I want to add, but it's currently a
working RC that I'll use and see what really needs fixing / adding.

This has no affiliation with the band or any orthopedic procedures. Is so named
due to the components that power it, and it's intended use.

Prereqs
-------

Requires [Perl Dancer](http://perldancer.org), and its
[Database Plugin](https://metacpan.org/module/Dancer::Plugin::Database), to run.
The app has several JS libs bundled in.  Please pay attention to the licensing on those
libs before you go hacking on that code :)


JS Libs (Bundled within)
----

Credit where credit is due. Most of the magic and voodoo is done by other
people's work. I just moshed it all together with voodoo of my own.

* [Backbone](http://backbonejs.org)
* [Underscore](http://underscorejs.org)
* [jQuery](http://jquery.com/)
* [jQuery Validation Plugin](http://jqueryvalidation.org/)
* [jQuery Cookie Plugin](http://plugins.jquery.com/jcookie/)
* [Twitter's Bootstrap](http://twitter.github.io/bootstrap/)
* [Moment.js](http://momentjs.com/)
* [Mustache Templates](http://mustache.github.io/)
* [Alex Gorbatchev's SyntaxHighlighter.](http://alexgorbatchev.com/SyntaxHighlighter/)

Persistance
-----------

Comes bundled with a SQLite DB for the moshes. But can be tweaked to use a
MySQL/Postgres/Oracle DB backend, should you wish. See the
[Dancer::Plugin::Database](https://metacpan.org/module/Dancer::Plugin::Database)
docs for how to do that.


Release 1.0
-----------

With release 1.0 comes a couple of new features such as raw mosh viewing and
mosh expiries.

Some changes have been made to the database to enable the latter to function.
Included in the db/ directory is an update SQL file which should update the
structure of your DB without losing all your moshes.


Expiring Moshes
---------------

With the addition of mosh expiries, something actually needs to expire them.
I've added a perl script that can be tailored to your STCM installation and set
to run at whatever interval you deem fit (every half hour should do the trick).

I did contemplate having the API clean up moshes. But the potential over-head
could slow down the response and make for bad Ux - hence the cron script. Just
be sure to point it at the location of your SQLite DB, or give it the connection
params for your real DB if that's how you're doing things.


