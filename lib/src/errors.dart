abstract class DCFError {}

class APIRetriableError extends DCFError {}

class APIProgrammingError extends DCFError {
  String message;
  APIProgrammingError(this.message);
  @override
  String toString() {
    return "APIProgrammingError: " + this.message;
  }
}

class APITokenError extends DCFError {}

class APIPermissionError extends APITokenError {}

class APIMalformedTokenError extends APITokenError {}

class APINotFoundError extends DCFError {}

class APIValidationError extends DCFError {
  Map<String, String> fields;
  String non_field;
  APIValidationError(this.fields, this.non_field);
}

class APINetworkError extends APIRetriableError {
  /** The error is likely due to a temporary network failure. The user should try the action again. */
}

class APIThrottledError extends APIRetriableError {}

DCFError deduceError(int httpStatusCode, Map<String, Object> backendResponse) {
  if (backendResponse.containsKey("message") &&
      backendResponse.containsKey("code")) {
    final code = backendResponse["code"] as String;
    final message = backendResponse["message"] as String;
    switch (code) {
      case "not_found":
        return APINotFoundError();
      case "throttled":
        return APIThrottledError();
      case "permission_denied":
        return APIPermissionError();
      case "authentication_failed":
        return APIMalformedTokenError();
      case "validation_error":
        final fields = Map<String, String>.from(
          backendResponse["fields"] as dynamic,
        );
        final non_field = backendResponse["non_field"] as String;
        return APIValidationError(fields, non_field);
      default:
        return APIProgrammingError(message);
    }
  }
  // We are not expecting an unknown error
  return APIProgrammingError(backendResponse.toString());
}
