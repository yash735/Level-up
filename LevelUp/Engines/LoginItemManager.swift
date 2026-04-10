//
//  LoginItemManager.swift
//  LEVEL UP — Phase 5
//
//  Manages launch-at-login via ServiceManagement's SMAppService.
//  Toggle in Settings; defaults ON.
//

import Foundation
import ServiceManagement

enum LoginItemManager {

    /// Whether the app is currently registered as a login item.
    static var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    /// Enable or disable launch at login. Returns true on success.
    @discardableResult
    static func setEnabled(_ enabled: Bool) -> Bool {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
            return true
        } catch {
            return false
        }
    }
}
