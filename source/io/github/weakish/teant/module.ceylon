"""I wrote teant to avoid writing Makefile for Ceylon projects.

   Run `teant --help` for usage.

   The name comes from tea (Ceylon) and ant (Java build tool)."""
native ("jvm")
module io.github.weakish.teant "0.0.0" {
    shared import ceylon.file "1.3.2";
    shared import ceylon.process "1.3.2";
    import io.github.weakish.sysexits "0.1.0";
    import java.base "8";
}
