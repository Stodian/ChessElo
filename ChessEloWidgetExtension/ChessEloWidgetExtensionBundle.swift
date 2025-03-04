//
//  ChessEloWidgetExtensionBundle.swift
//  ChessEloWidgetExtension
//
//  Created by Ethan Reid on 23/02/2025.
//

import WidgetKit
import SwiftUI

@main
struct ChessEloWidgetExtensionBundle: WidgetBundle {
    var body: some Widget {
        ChessEloWidgetExtension()
        ChessEloWidgetExtensionControl()
        ChessEloWidgetExtensionLiveActivity()
    }
}
