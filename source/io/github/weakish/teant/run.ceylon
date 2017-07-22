import io.github.weakish.sysexits {
    CommandLineUsageError,
    IOError
}
import io.github.weakish.teant.ceylon {
    Task
}


"Utilimate exception handler."
suppressWarnings("expressionTypeNothing")
shared void run() {
    try {
        main();
    } catch (CommandLineUsageError e) {
        display_help();
        process.writeErrorLine("\n\n" + e.message);
        process.exit(e.exit_code);
    } catch (IOError e) {
        process.writeErrorLine(e.message);
        process.exit(e.exit_code);
    } catch (TaskFailedException e) {
        process.writeErrorLine(e.message);
        process.exit(e.exit_code);
    }
}

void main() {
    switch (argument = process.arguments.first)
    case (is Null) {
        display_help();
    }
    case ("help"|"--help"|"-h") {
        display_help();
    }
    case ("version"|"--version"|"-V") {
        print("teant " + `module`.version);
    }
    case ("build"|"compile") {
        Task.build.execute();
    }
    case ("test") {
        Task.test.execute();
    }
    case ("build-js"|"compile-js") {
        Task.build_js.execute();
    }
    case ("build-all"|"compile-all") {
        Task.build_all.execute();
    }
    case ("test-js") {
        Task.test_js.execute();
    }
    case ("test-all") {
        Task.test_all.execute();
    }
    case ("doc") {
        Task.ceylon_doc.execute();
    }
    case ("jar"|"fat-jar") {
        Task.jar.execute();
    }
    case ("install") {
        Task.install.execute();
    }
    case ("uninstall") {
        Task.uninstall.execute();
    }
    else {
        throw CommandLineUsageError("Invalid argument: ``argument``");
    }
}


void display_help() {
    String help_info = "usage: teant <task>

                        Options:

                          -h, --help       show this help message and exit
                          -V, --version    show version number and exit

                        tasks:

                          build            ceylon compile (java)
                          test             ceylon test (java)
                          build-js         ceylon compile-js
                          build-all        compile java and js
                          test-js          ceylon test-js
                          test-all         ceylon test && ceylon test-js
                          doc              ceylon doc
                          jar              ceylon fat-jar
                          install          install exectuable to ~/bin
                          uninstall        uninstall from ~/bin
                          help             same as --help
                          version          same as --version\n";

    print(help_info);
}
