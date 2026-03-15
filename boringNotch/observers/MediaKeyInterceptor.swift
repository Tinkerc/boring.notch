//
//  MediaKeyInterceptor.swift
//  boringNotch
//
//  Created by Alexander on 2025-11-23.
//

import Foundation
import AppKit

/// MediaKeyInterceptor has been removed as part of app slimming.
/// System media keys are now handled by macOS default behavior.
final class MediaKeyInterceptor {
    static let shared = MediaKeyInterceptor()

    private init() {}

    /// Start intercepting media keys - no-op, kept for backwards compatibility
    func start(promptIfNeeded: Bool = false) async {
        return
    }

    /// Stop intercepting media keys - no-op, kept for backwards compatibility
    func stop() {
        return
    }

    /// Request accessibility authorization - no-op, kept for backwards compatibility
    func requestAccessibilityAuthorization() {
        return
    }

    /// Ensure accessibility authorization - no-op, kept for backwards compatibility
    func ensureAccessibilityAuthorization(promptIfNeeded: Bool = false) async -> Bool {
        return false
    }
}
