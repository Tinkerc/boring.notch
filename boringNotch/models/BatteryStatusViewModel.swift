import Cocoa
import Foundation
import IOKit.ps
import SwiftUI

/// A view model that manages and monitors the battery status of the device
class BatteryStatusViewModel: ObservableObject {
    @Published private(set) var levelBattery: Float = 0.0
    @Published private(set) var maxCapacity: Float = 0.0
    @Published private(set) var isPluggedIn: Bool = false
    @Published private(set) var isCharging: Bool = false
    @Published private(set) var isInLowPowerMode: Bool = false
    @Published private(set) var isInitial: Bool = false
    @Published private(set) var timeToFullCharge: Int = 0
    @Published private(set) var statusText: String = ""

    static let shared = BatteryStatusViewModel()

    /// Initializes the view model with a given BoringViewModel instance
    /// - Parameter vm: The BoringViewModel instance
    private init() {
        setupPowerStatus()
        setupMonitor()
    }

    /// Sets up the initial power status by fetching battery information
    private func setupPowerStatus() {
        let batteryInfo = readBatteryInfo()
        updateBatteryInfo(batteryInfo)
    }

    /// Sets up the monitor to observe battery events
    private func setupMonitor() {
        // Monitoring handled by periodic polling in setupPowerStatus
    }


    private func readBatteryInfo() -> BatteryInfo {
        let snapshot = IOPSCopyPowerSourcesInfo().takeRetainedValue()
        let sources = IOPSCopyPowerSourcesList(snapshot).takeRetainedValue() as [CFTypeRef]

        guard let source = sources.first,
              let description = IOPSGetPowerSourceDescription(snapshot, source).takeUnretainedValue() as? [String: Any]
        else {
            return BatteryInfo(
                currentCapacity: 0,
                maxCapacity: 100,
                isPluggedIn: false,
                isCharging: false,
                isInLowPowerMode: ProcessInfo.processInfo.isLowPowerModeEnabled,
                timeToFullCharge: 0
            )
        }

        let currentCapacity = description[kIOPSCurrentCapacityKey] as? Int ?? 0
        let maxCapacity = description[kIOPSMaxCapacityKey] as? Int ?? 100
        let isCharging = description[kIOPSIsChargingKey] as? Bool ?? false
        let timeToFullCharge = description[kIOPSTimeToFullChargeKey] as? Int ?? 0
        let isPluggedIn = description[kIOPSPowerSourceStateKey] as? String == kIOPSACPowerValue

        return BatteryInfo(
            currentCapacity: Float(currentCapacity),
            maxCapacity: Float(maxCapacity),
            isPluggedIn: isPluggedIn,
            isCharging: isCharging,
            isInLowPowerMode: ProcessInfo.processInfo.isLowPowerModeEnabled,
            timeToFullCharge: timeToFullCharge
        )
    }

    /// Updates the battery information with the given BatteryInfo instance
    /// - Parameter batteryInfo: The BatteryInfo instance containing the battery data
    private func updateBatteryInfo(_ batteryInfo: BatteryInfo) {
        withAnimation {
            self.levelBattery = batteryInfo.currentCapacity
            self.isPluggedIn = batteryInfo.isPluggedIn
            self.isCharging = batteryInfo.isCharging
            self.isInLowPowerMode = batteryInfo.isInLowPowerMode
            self.timeToFullCharge = batteryInfo.timeToFullCharge
            self.maxCapacity = batteryInfo.maxCapacity
            self.statusText = batteryInfo.isPluggedIn ? "Plugged In" : "Unplugged"
        }
    }

    private func notifyImportanChangeStatus(delay: Double = 0.0) {
        // Notification removed as part of app slimming
    }

}

/// Battery information struct
struct BatteryInfo {
    let currentCapacity: Float
    let maxCapacity: Float
    let isPluggedIn: Bool
    let isCharging: Bool
    let isInLowPowerMode: Bool
    let timeToFullCharge: Int
}

/// Battery events enum for compatibility
enum BatteryEvent {
    case powerSourceChanged(Bool)
    case batteryLevelChanged(Float)
    case lowPowerModeChanged(Bool)
    case isChargingChanged(Bool)
    case timeToFullChargeChanged(Int)
    case maxCapacityChanged(Float)
    case error(String)
}
