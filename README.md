# m2-extensions

Since 3.3.1, maven supports loads project extensions from `<project-base>/.mvn/extensions.xml`. This project let maven (>= 3.0) use a similar way to load personal extensions specifying in `$HOME/.m2/extensions.xml`.

## Install

```bash
git clone https://github.com/gzm55/m2-extensions.git /path/to/m2-extensions
cd /path/to/m2-extensions
./mvnw
```

Then the loader is injected into `$HOME/.mavenrc`, and each time you update `$HOME/.m2/extensions.xml`, the extensions will be resolved on the fly, copied into `$HOME/.m2/ext/`, then loaded from `-Dmaven.ext.class.path=...`. Result of resolving will be saved. Next time running maven, the loader just add the local jars into the command line via `MAVEN_OPTS`.

## Environment Variable

* `MAVEN_SKIP_M2_EXT` if not empty, skip loading .m2/ext directory
* `M2_EXTENSIONS_HOME` local clone of m2-extensions project. if unset, loader will try to `git clone` a temp one.

## Path Structure

* `$HOME/.m2/extensions.xml` settings, format is the same as `<project-base>/.mvn/extensions.xml`
* `$HOME/.m2/ext/*.jar` resolved jars for user defined extensions
* `$HOME/.m2/ext/extensions.xml` a cached version of `$HOME/.m2/extensions.xml`, used for detecting user updates
* `$HOME/.m2/ext.<timestamp>.bak/` backup of `$HOME/.m2/ext/` when resolving

## Limit

* loader part do not support windows, so on windows, you have to manually edit `mavenrc_pre.cmd`, and set MAVEN_OPTS to contain `-Dmaven.ext.class.path=[all jars in .m2/ext]`
* `mvn -Dmaven.ext.class.path=xxx` will disable extensions defined in `$HOME/.m2/extensions.xml`, not merge together.
* when conflicts, user level extensions will be loaded before project level ones.

## What maven extensions should be defined in user level?

A user level extension should be enhancement to the invoked maven distribution, and should not notably change the semantic or building behavior of the pom.xml. That is the project should be built successfully with or without user level extensions. Such as `takari-local-repository`, `takari-smart-builder`, `aether-connector-okhttp` and etc.
