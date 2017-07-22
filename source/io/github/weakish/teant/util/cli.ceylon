import ceylon.process {
    Process,
    createProcess
}
import ceylon.file {
    Path,
    Reader
}


shared Boolean is_windows() {
    String os = operatingSystem.name;
    if (os == "windows") {
        return true;
    } else {
        return false;
    }
}

"Like createProcess but try to convert command to absolute path."
shared Process create_process(
        String command, String[] arguments,
        Path path) {
    if (is_windows()) {
        Process process = createProcess {
            command = "cmd";
            arguments = ["/c", command].append(arguments);
            path = path;
        };
        return process;
    } else {
        Process process = createProcess {
            command = which(command, path);
            arguments = arguments;
            path = path;
        };
        return process;
    }
}

String which(String cmd, Path path) {
    Process process = createProcess {
        command = "which";
        arguments = [cmd];
        path = path;
    };
    if (is Reader reader = process.output) {
        if (exists line = reader.readLine()) {
            return line.trimmed;
        } else {
            return cmd;
        }
    } else {
        return cmd;
    }
}

