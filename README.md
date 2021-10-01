# blackmagic

> just a bit of makefile blackmagic

Blackmagic creates complex cached dependency chains that track changes on
individual files. It can be used to format the code and run tests against
only the files that updated. This significantly increases the speed of builds
and development in a language and ecosystem agnostic way without sacrificing
enforcement of critical scripts and jobs.

## Features

### Dynamic Batched Dependencies

Traditionally there are two strategies for dealing with dependencies
in Makefile, **running a command once for batched dependencies** or
**running a command for each individual dependency**.

It is common for Makefiles used with low level compilers (like a
C compiler) to run a command once for every dependency, which is
great because it enables caching for each individual file in the
project. However, the downside for this strategy is that it is slow
because it must run a separate process for each file.

Some compilers and transpilers (like webpack) are not meant to
compile individual files. This means Makefiles used with these
compilers must batch all of the targets. Of course in this situation
make loses the ability to cache individual targets, because when a
single file is updated, all of the files are processed.

This project enables a way to create Makefiles that leverage the best
of both strategies. Using actions, you can run a command once, but only
on the dependencies that updated. A really great use case for this is
linting files.

Imagine I have a project and I want to lint only the files that updated.
A traditional Makefile would run the linter once on each file. This is slow
and is not able to produce an aggregated output. Of course we could simply
lint all of the files any time a single file changes, but again that is
slower than just linting the files that changed. Using actions, we can
run the linter once, but only on the dynamic set of dependencies that updated.

### Action chains

Actions can depend on other actions forming a chain of operations that are
efficiently cached.

## Terminology

### Actions

actions are special targets that operate on a batched dynamic set of dependencies
that updated

### Deps

deps are files that the action tracks and includes in an operation when they are
updated

### Targets

targets are regular Makefile targets that can be attached to an action
