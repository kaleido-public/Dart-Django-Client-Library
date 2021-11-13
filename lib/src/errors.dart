abstract class DCFError {}

class InputError extends DCFError {
  /** When you see this error, the user needs to change the input, before
     * trying the action again. */
}

class RetriableError extends DCFError {}

class ProgrammingError extends DCFError {
  String message;
  ProgrammingError(this.message);
  @override
  String toString() {
    return "ProgrammingError: " + this.message;
  }
}

class ResourceError extends DCFError {}

class NotFound extends ResourceError {}

class MissingInput extends InputError {
  Set<String> fields;
  MissingInput(this.fields);
}

class InvalidInput extends InputError {
  Map<String, List<String>> fields;
  List<String> general;
  InvalidInput(this.fields, this.general);
}

class NetworkError extends RetriableError {
  /** The error is likely due to a temporary network failure. The user should try the action again. */
}

class Throttled extends RetriableError {}

DCFError deduceError(int httpStatusCode, Map<String, Object> backendResponse) {
  if (backendResponse.containsKey("message") &&
      backendResponse.containsKey("code")) {
    final code = backendResponse["code"] as String;
    final message = backendResponse["message"] as String;
    switch (code) {
      case "not_found":
        return NotFound();
      case "throttled":
        return Throttled();
      default:
        return ProgrammingError(message);
    }
  } else if (httpStatusCode == 400) {
    final invalidFields = <String, List<String>>{};
    final missingFields = <String>{};
    for (final entry in backendResponse.entries) {
      final field = entry.key;
      var validationErrors = entry.value as List<dynamic>;
      for (final error in validationErrors) {
        final code = error["code"] as String;
        final message = error["message"] as String;
        switch (code) {
          case "required":
            missingFields.add(field);
            break;
          case "invalid":
          case "null":
          case "does_not_exist":
          default:
            var messages = invalidFields[field] ?? [];
            messages.add(message);
            invalidFields[field] = messages;
            break;
        }
      }
    }
    if (missingFields.isNotEmpty) {
      return MissingInput(missingFields);
    }
    if (invalidFields.isNotEmpty) {
      return InvalidInput(invalidFields, []);
    }
  }
  // We are not expecting an unknown error
  return ProgrammingError(backendResponse.toString());
}
