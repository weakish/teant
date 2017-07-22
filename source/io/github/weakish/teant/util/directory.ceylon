import ceylon.file {
    Path,
    File,
    Link,
    Nil,
    Directory
}

shared File create_overwrite(File|Nil target) {
    switch(target)
    case (is Nil) {
        return target.createFile();
    }
    case (is File) {
        return target;
    }
}

shared Directory? project_root(Path directory, String dotDirectoryName) {
    assert (is Directory dir = directory.resource);
    switch (dotDirectory = dir.childResource(dotDirectoryName))
    case (is Directory) {
        return dir;
    }
    case (is File|Nil|Link) {
        switch (is_root = dir.path.root)
        case (true) {
            return null;
        }
        case (false) {
            return project_root(dir.path.parent, dotDirectoryName);
        }
    }
}

shared Comparison? compare_directories(Directory directory, Directory other) {
    String dir = directory.path.absolutePath.string;
    String other_dir = directory.path.absolutePath.string;
    if (dir == other_dir) {
        return equal;
    } else if (dir.startsWith(other_dir)) {
        return smaller;
    } else if (other_dir.startsWith(dir)) {
        return larger;
    } else {
        return null;
    }
}

shared Directory? sub_directory(Directory parent, String sub_directory_name) {
    switch (sub = parent.childResource(sub_directory_name))
    case (is Directory) {
        return sub;
    }
    else {
        return null;
    }
}
