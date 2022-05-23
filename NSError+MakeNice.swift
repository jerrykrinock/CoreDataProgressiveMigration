import Foundation

extension NSError {
    convenience init(
        domain: String? = Bundle.mainAppBundle().bundleIdentifier,
        code: Int,
        localizedDescription: String,
        underlyingError: Error? = nil,
        localizedRecoverySuggestion: String? = nil
    ) {
        var userInfo : [String : Any] = [NSLocalizedDescriptionKey : localizedDescription]

        if let underlyingError = underlyingError {
            userInfo[NSUnderlyingErrorKey] = underlyingError
        }
        if let localizedRecoverySuggestion = localizedRecoverySuggestion {
            userInfo[NSLocalizedRecoverySuggestionErrorKey] = localizedRecoverySuggestion
        }

        self.init(domain:domain ?? "No bundle ID !?!?",
                code: code,
                userInfo: userInfo)
    }
}


