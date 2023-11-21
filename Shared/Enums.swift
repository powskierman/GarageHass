//
//  Enums.swift
//  WatchGarageHass Watch App
//
//  Created by Michel Lapointe on 2023-11-21.
//

import Foundation

enum EntityType {
    case door(Door)
    case alarm

    enum Door {
        case left
        case right
    }
}
