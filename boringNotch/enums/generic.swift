//
//  generic.swift
//  boringNotch
//
//  Created by Harsh Vardhan  Goswami  on 04/08/24.
//

import Foundation
import Defaults

public enum Style {
    case notch
    case floating
}

public enum ContentType: Int, Codable, Hashable, Equatable {
    case normal
    case menu
    case settings
}

public enum NotchState {
    case closed
    case open
}

public enum NotchViews {
    case home
    case apps
}

enum SettingsEnum {
    case general
    case about
    case mediaPlayback
}

enum HideNotchOption: String, Defaults.Serializable, Equatable {
    case always
    case nowPlayingOnly
    case never
}
