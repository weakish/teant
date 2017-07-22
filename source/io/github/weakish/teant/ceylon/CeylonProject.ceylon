import io.github.weakish.teant {
    Project,
    TaskFailedException
}
import ceylon.file {
    Directory,
    current,
    File,
    Link,
    Nil,
    Reader,
    home,
    Path
}
/* FIXME `ceylon doc` errors out on this:

```
error [imported declaration not found: 'project_root' might be misspelled or does not belong to this package] at 21:4-21:15 of io/github/weakish/teant/ceylon/CeylonProject.ceylon
error [imported declaration not found: 'compare_directories' ...
...
error [imported declaration not found: 'uninstall_file' ...
error [function or value is not defined: 'project_root' might be misspelled or is not imported (did you mean to import it from 'io.github.weakish.teant.util'?)] at 43:30-43:41 of io/github/weakish/teant/ceylon/CeylonProject.ceylon
...
```

Thus API doc cannot be built.

This module compiles and runs successfully.
Intellij-ceylon also does not report any problem.

I tested it on another machine, and `ceylon doc` gives the same error.

I guess this is caused by a bug in `ceylon doc`.
But I have no idea what part of code triggers this bug.
 */
import io.github.weakish.teant.util {
    project_root,
    compare_directories,
    sub_directory,
    create_process,
    is_windows,
    create_overwrite,
    set_executable,
    uninstall_file
}
import ceylon.process {
    Process
}
import io.github.weakish.sysexits {
    CanNotCreateFileError,
    IOError
}



shared class CeylonProject() satisfies Project {

    shared actual Directory? root() {
        Directory? git_root = project_root(current, ".git");
        Directory? ceylon_root = project_root(current, ".ceylon");

        switch (ceylon_root)
        case (is Null) {
            switch (git_root)
            case (is Null) {
                return null;
            }
            case (is Directory) {
                return check_root(git_root);
            }
        }
        else {
            switch (git_root)
            case (is Null) {
                return check_root(ceylon_root);
            }
            case (is Directory) {
                if (has_source_directory(ceylon_root)) {
                    if (has_source_directory(git_root)) {
                        return choose_smaller(ceylon_root, git_root);
                    } else {
                        return ceylon_root;
                    }
                } else if (has_source_directory(git_root)) {
                    return git_root;
                } else {
                    return null;
                }
            }
        }
    }

    Directory? choose_smaller(Directory directory, Directory other) {
        switch (comparision = compare_directories(directory, other))
        case (equal|smaller) {
            return directory;
        }
        case (larger) {
            return other;
        }
        else {
            return null;
        }
    }

    Directory? check_root(Directory root) {
        if (has_source_directory(root)) {
            return root;
        } else {
            return null;
        }
    }

    Boolean has_source_directory(Directory root) {
        switch (source_directory = source(root))
        case (is Directory) {
            return true;
        }
        case (is Null) {
            return false;
        }
    }

    Directory? source(Directory root) {
        switch (config = config_file(root))
        case (is File) {
            switch (source_directory = get_source(config))
            case (is String) {
                return sub_directory(root, source_directory);
            }
            case (is Null) {
                return sub_directory(root, "source");
            }
        }
        case (is Null) {
            return sub_directory(root, "source");
        }
    }

    File? config_file(Directory root) {
        switch (dot_ceylon = root.childResource(".ceylon"))
        case (is Directory) {
            switch (config = dot_ceylon.childResource("config"))
            case (is File) {
                return config;
            }
            case (is Directory|Link|Nil) {
                return null;
            }
        }
        case (is File|Link|Nil) {
            return null;
        }
    }

    String? get_source(File config) {
        try (reader = config.Reader()) {
            while (is String line = reader.readLine()) {
                if (line.startsWith("source=")) {
                    String source = line["source=".size...];
                    return source.trimmed;
                }
            }
            return null;
        }
    }


    shared Boolean compile_java() {
        Boolean result = ceylon_command("compile");
        return result;
    }
    shared Boolean compile_js() {
        return ceylon_command("compile-js");
    }
    shared Boolean compile_all() {
        return depends(compile_java, compile_js);
    }

    shared String? version() {
        assert (is Directory root = root());
        Process ceylon = create_process {
            command = "ceylon";
            arguments = ["version"];
            path = root.path;
        };
        ceylon.waitForExit();
        if (is Reader reader = ceylon.output) {
            if (exists line = reader.readLine()) {
                return line.trimmed;
            } else {
                return null;
            }
        } else {
            return null;
        }
    }

    shared Boolean test_java() {
        String? module_version = version();
        assert (exists module_version);
        if (depends(compile_java)) {
            return ceylon_command("test", module_version);
        } else {
            return false;
        }
    }
    shared Boolean test_js() {
        String? module_version = version();
        assert (exists module_version);
        if (depends(compile_js)) {
            return ceylon_command("test-js", module_version);
        } else {
            return false;
        }
    }
    shared Boolean test_all() {
        return depends(test_java, test_js);
    }

    shared Boolean fat_jar() {
        String? module_version = version();
        assert (exists module_version);
        if (depends(compile_java)) {
            return ceylon_command("fat-jar", module_version);
        } else {
            return false;
        }
    }
    shared Boolean doc() {
        String? module_version = version();
        assert (exists module_version);
        return ceylon_command(
            "doc",
            module_version, "--resource-folder=resources");
    }

    shared Boolean install() {
        String? module_version = version();
        assert (exists module_version);

        String name = jar_name(module_version);
        File|Nil target = installation_target(name);

        File? jar = jar_file(name);
        if (exists jar) {
            jar.copyOverwriting(target);
            install_wrap_script(module_version, target.path);
            return true;
        } else {
            if (depends(fat_jar)) {
                File? new_jar = jar_file(name);
                if (exists new_jar) {
                    new_jar.copyOverwriting(target);
                    install_wrap_script(module_version, target.path);
                    return true;
                } else {
                    throw IOError("Exception: ``name`` is unavailable.");
                }
            } else {
                throw TaskFailedException("Exception: creating fat jar file failed!");
            }
        }
    }

    shared Boolean uninstall() {
        String? module_version = version();
        assert (exists module_version);

        uninstall_jar(module_version);
        uninstall_wrap_script(module_version);

        return true;
    }

    void uninstall_jar(String module_version) {
        String name = jar_name(module_version);
        uninstall_file(installation_target(name));
    }

    void uninstall_wrap_script(String module_version) {
        String short_name = module_base_name(module_version);
        if (is_windows()) {
            uninstall_file(installation_target(short_name + ".bat"));
        } else {
            uninstall_file(installation_target(short_name));
        }
    }

    void install_wrap_script(String module_version, Path target) {
        String short_name = module_base_name(module_version);
        File target_file;
        String command_line;
        if (is_windows()) {
            command_line = wrapping_command(target, false);
            target_file = create_overwrite(installation_target(short_name + ".bat"));
            try (writer = target_file.Overwriter()) {
                writer.writeLine("@echo off");
                writer.writeLine(command_line);
            }
        } else {
            command_line = wrapping_command(target, true);
            target_file = create_overwrite(installation_target(short_name));
            try (writer = target_file.Overwriter()) {
                writer.writeLine("#!/bin/sh");
                writer.writeLine(command_line);
            }
        }
        set_executable(target_file);
    }


    String module_base_name(String module_name) {
        String version_stripped = module_name.split(Character.equals('/')).first;
        return version_stripped.split(Character.equals('.')).last;
    }

    String wrapping_command(Path target, Boolean unix) {
        String arguments;
        if (unix) {
            arguments = "\"$@\"";
        } else {
            arguments = "%*";
        }
        return "java -jar ``target.absolutePath`` ``arguments``";
    }

    String jar_name(String module_version) {
        return module_version.replace("/", "-") + ".jar";
    }

    File|Nil installation_target(String name, File|Nil|Directory|Null linked_target = null) {
        switch (target = home_bin().childResource(name))
        case (is File|Nil) {
            return target;
        }
        case (is Directory) {
            throw CanNotCreateFileError(
                "Exception: ~/bin/``name`` is a directory, but a file is expected!");
        }
        case (is Link) {
            return installation_target(name, target.linkedResource);
        }
    }

    Directory home_bin(Directory|File|Nil|Null linked_target = null) {
        switch (bin = home.childPath("bin").resource)
        case (is Directory) {
            return bin;
        }
        case (is Nil) {
            return bin.createDirectory(true);
        }
        case (is File) {
            throw CanNotCreateFileError("Exception: ~/bin is a file, but a directory is expected!");
        }
        case (is Link) {
            return home_bin(bin.linkedResource); 
        }
    }

    File? jar_file(String jar_name) {
        assert (is Directory root = root());
        switch (location = root.childResource(jar_name))
        case (is File) {
            return location;
        }
        case (is Directory|Nil|Link) {
            return null;
        }
    }

    Boolean ceylon_command(String* arguments) {
        assert (is Directory root = root());
        Process ceylon = create_process {
            command = "ceylon";
            arguments = arguments;
            path = root.path;
        };
        Integer exist_status = ceylon.waitForExit();
        if (exist_status == 0) {
            return true;
        } else {
            if (is Reader reader = ceylon.error) {
                while (exists line = reader.readLine()) {
                    process.writeErrorLine(line);        
                }
            }
            return false;
        }
    }

    Boolean depends(Boolean()* dependencies) {
        for (dependency in dependencies) {
            if (!dependency()) {
                return false;
            }
        }
        return true;
    }

    shared actual Boolean default() {
        return compile_java();
    }
}

shared class Task
        of build|test|build_js|build_all|test_js|test_all|
           ceylon_doc|jar|
           install|uninstall
{
    shared String name;

    // TODO tasks should be void and throw unchecked exception.
    Boolean() task;

    CeylonProject ceylon_project = CeylonProject();

    shared new build {
        name = "build";
        task = ceylon_project.compile_java;
    }
    shared new test {
        name = "test";
        task = ceylon_project.test_java;
    }
    shared new build_js {
        name = "build-js";
        task = ceylon_project.compile_js;
    }
    shared new build_all {
        name = "build-all";
        task = ceylon_project.compile_all;
    }
    shared new test_js {
        name = "test-js";
        task = ceylon_project.test_js;
    }
    shared new test_all {
        name = "test-all";
        task = ceylon_project.test_all;
    }
    shared new ceylon_doc {
        name = "doc";
        task = ceylon_project.doc;
    }
    shared new jar {
        name = "jar";
        task = ceylon_project.fat_jar;
    }
    shared new install {
        name = "install";
        task = ceylon_project.install;
    }
    shared new uninstall {
        name = "uninstall";
        task = ceylon_project.uninstall;
    }

    shared void execute() {
        if (!task()) {
            throw TaskFailedException("``name`` FAIL!");
        }
    }
}