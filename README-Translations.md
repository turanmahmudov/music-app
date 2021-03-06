Updating translations
=====================

Translations for the Music app happen in [Launchpad Translations](https://translations.launchpad.net/music-app) and are automatically committed daily on the trunk branch in the po/ folder.

They are then built and installed as part of the package build, so that
developers don't really need to worry about them.

However, there is one task that needs to be taken care of: exposing new
translatable messages to translators. So whenever you add new translatable
messages in the code, make sure to follow these steps:

 1. Run click-buddy retaining the build directory:
    $ click-buddy --dir . --no-clean
 2. Copy the .pot file from the <build dir> mentioned in the output to your
    original source:
    $ cp <build dir>/po/*.pot po/
 3. Commit the generated .pot file:
    $ bzr commit -m "Updated translation template"
 4. Push the branch and send a merge proposal as usual

And that's it, once the branch lands Launchpad should take care of all the rest!

Behind the scenes
=================

Behind the scenes, whenever the po/*.pot file (also known as translations template) is committed to trunk Launchpad reads it and updates the translatable strings exposed in the web UI. This will enable translators to work on the new strings.
The translations template contains all translatable strings that have been extracted from the source code files.

Launchpad will then store translations in its database and will commit them daily in the form of textual po/*.po files to trunk. The PO files are also usually referred to as the translations files. You'll find a translation file for each language the app has got at least a translated message available for.

Translations for core apps follow the standard [gettext format](https://www.gnu.org/software/gettext/).

 [Launchpad Translations](https://translations.launchpad.net/music-app)
 [Gettext format](https://www.gnu.org/software/gettext/)
