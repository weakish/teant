import ceylon.file {
    File,
    Nil
}
import java.io {
    JFile=File
}


shared void set_executable(File file) {
    JFile jFile = JFile(file.path.string);
    jFile.setExecutable(true, false);
}

shared void uninstall_file(File|Nil target) {
    switch (target)
    case (is File) {
        target.delete();
    }
    case (is Nil) {
        process.writeErrorLine("Info: ``target.path`` does not exist. Skip deleting it.");
    }
}