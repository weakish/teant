shared class TaskFailedException(message) extends Exception(message) {
    shared actual String message;
    shared Integer exit_code = 1;
}