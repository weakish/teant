import ceylon.file {
    Directory,
    current
}
import io.github.weakish.teant.util {
    project_root
}


shared interface Project {
    shared default Directory? root() {
        return project_root(current, ".git");
    }
    shared formal void default();
}