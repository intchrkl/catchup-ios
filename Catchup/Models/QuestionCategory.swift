//
//  QuestionCategory.swift
//  Catchup
//
//  Created by Intat Tochirakul on 8/11/2568 BE.
//

import Foundation

enum QuestionCategory: String, CaseIterable, Identifiable {
    case selfReflection = "Self Reflection"
    case memories = "Memories"
    case relationships = "Relationships"
    case goals = "Goals"
    case gratitude = "Gratitude"
    case wouldYouRather = "Would You Rather"

    var id: String { rawValue }
    var systemPrompt: String {
        switch self {
        case .selfReflection:
            return "Write a thoughtful, single-sentence self-reflection question for a young adult."
        case .memories:
            return "Write a single-sentence question that prompts a meaningful memory."
        case .relationships:
            return "Write a single-sentence question that helps someone reflect on their relationships."
        case .goals:
            return "Write a concise question that surfaces personal goals and motivations."
        case .gratitude:
            return "Write a short question that encourages gratitude for specific moments."
        case .wouldYouRather:
            return "Write a creative response to some imaginative 'would you rather' scenarios."
        }
    }
}
