//
//  GarageHassApp.swift
//  GarageNew
//
//  Created by Michel Lapointe on 2022-10-22.
//

import SwiftUI
import HassFramework
import Combine
import os
import SwiftUI

@main
struct GarageHassApp: App {
    @Environment(\.scenePhase) private var scenePhase
    let garageRestManager = GarageRestManager.shared // Reference GarageRestManager.shared for easier access
 
    init() {
     }

    var body: some Scene {
          WindowGroup {
              PhoneView()
                  .environmentObject(GarageRestManager.shared)
                  .onChange(of: scenePhase) {
                      switch scenePhase {
                      case .active:
                          appDidBecomeActive()
                      case .inactive, .background:
                          appDidEnterBackground()
                      default:
                          break
                      }
                  }
          }
      }
    func appDidBecomeActive() {
        print("App is now active - Refreshing data from RESTful API")
        garageRestManager.fetchInitialState()
    }

    func appDidEnterBackground() {
        print("App is now in background")
        // Any necessary clean-up for REST API
        // For example, cancelling ongoing requests
//        GarageRestManager.shared.cancelOngoingRequests()
    }
  }
