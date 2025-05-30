import Foundation

/// Enumerates the priorites that an ``AppInitializer`` can have.
///
/// An initializer's priority determines _when_ during the app lifecycle the initializer will get executed.
/// For more information, see <doc:DefiningInitializers#Setting-Initializer-Priority>
public enum InitializerPriority: Int {
    
    /// The highest priority. Initializers with this priority should execute once, as soon as the app launches.
    case appLaunch = 10
    
    /// The lowest priority. Initializers with this priority should execute each time the app enters the "active" scene phase.
    case appActive = 20
}
