teant
=====

I wrote teant to avoid writing Makefile for Ceylon projects.

Install
-------

Clone this repository:

    git clone https://github.com/weakish/teant.git
    cd teant

To install teant to `~/bin` with teant:

    teant install

To install teant without teant:

    ceylon compile
    ceylon fat-jar $(ceylon version)
    # on unix
    mv io.github.weakish.teant-0.0.0.jar ~/bin/
    echo '#!/bin/sh' > ~/bin/teant
    echo 'java -jar ~/bin/io.github.weakish.teant-0.0.0.jar "$@"' >> ~/bin/teant
    # on windows
    mv io.github.weakish.teant-0.0.0.jar %HOME%\bin
    echo '@echo off' > %HOME%\bin\teant.bat
    echo 'java -jar %HOME%\io.github.weakish.teant-0.0.0.jar %*' >> %HOME%\bin\teant.bat
    
### Uninstall

#### On Unix

    cd teant
    teant uninstall
    
#### On Windows
    
    del %HOME%\bin\io.github.weakish.teant-0.0.0.jar
    del %HOME%\bin\teant.bat
    
Usage
-----

    teant help

Doc
---

<https://weakish.github.io/teant/api/>

Naming
------

The name comes from tea (Ceylon) and ant (Java build tool)."""

License
-------

0BSD