import Foundation

/// Enumerates the possible states of App Initialization.
///
/// App Initialization goes through several states during the lifecyle of the app.
/// The ``InitManager`` exposes  the current initialization state using values
/// from this enumeration.
@frozen
public enum InitializationState: CustomStringConvertible {
    
    /// An Initialization State that indicates that initialization has not completed, and has not failed.
    /// Initialization has not started yet, or is currently running.
    case pending
    
    /// An Initialization State tht indicates that all initializers have executed successfully.
    case complete
    
    /// An Initialization State that indicates initialization failed with an error.
    ///
    /// - Parameters:
    ///   - error: An ``AppInitializationError`` indicating the reason for failure.
    case failed(error: Error)
    
    
    public var description: String {
        switch self {
        case .pending: return "Pending"
        case.complete: return "Complete"
        case .failed(_): return "Failed"
        }
    }

}

extension InitializationState: Equatable {
    
    /// Compare two Initialization State values.
    ///
    /// Initialization States are equal if both states are pending, both states are complete, or both states are failed.
    /// If both states are failed, it does not matter what the error value is, the two states are considered equal.
    public static func == (lhs: InitializationState, rhs: InitializationState) -> Bool {
        switch (lhs, rhs) {
            case (.pending, .pending):
                return true
            case (.complete, .complete):
                return true
            case (.failed(_), .failed(_)):
                return true
            default:
                return false
        }
    }
}
