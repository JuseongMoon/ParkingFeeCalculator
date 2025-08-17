//
//  ParkingFeeCalculatorWidgetLiveActivity.swift
//  ParkingFeeCalculatorWidget
//
//  Created by 문주성 on 8/17/25.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct ParkingFeeCalculatorWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct ParkingFeeCalculatorWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: ParkingFeeCalculatorWidgetAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                Text("Hello \(context.state.emoji)")
            }
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Text("Leading")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Trailing")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Bottom \(context.state.emoji)")
                    // more content
                }
            } compactLeading: {
                Text("L")
            } compactTrailing: {
                Text("T \(context.state.emoji)")
            } minimal: {
                Text(context.state.emoji)
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}

extension ParkingFeeCalculatorWidgetAttributes {
    fileprivate static var preview: ParkingFeeCalculatorWidgetAttributes {
        ParkingFeeCalculatorWidgetAttributes(name: "World")
    }
}

extension ParkingFeeCalculatorWidgetAttributes.ContentState {
    fileprivate static var smiley: ParkingFeeCalculatorWidgetAttributes.ContentState {
        ParkingFeeCalculatorWidgetAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: ParkingFeeCalculatorWidgetAttributes.ContentState {
         ParkingFeeCalculatorWidgetAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: ParkingFeeCalculatorWidgetAttributes.preview) {
   ParkingFeeCalculatorWidgetLiveActivity()
} contentStates: {
    ParkingFeeCalculatorWidgetAttributes.ContentState.smiley
    ParkingFeeCalculatorWidgetAttributes.ContentState.starEyes
}
