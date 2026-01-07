//
//  PromptService.swift
//  Catchup
//
//  Created by Intat Tochirakul on 8/11/2568 BE.
//

import Foundation

protocol PromptServiceType {
    func generateQuestion(for category: QuestionCategory) async throws -> String
}

/// MVP: mock first so you can ship UI now
struct MockPromptService: PromptServiceType {
    func generateQuestion(for category: QuestionCategory) async throws -> String {
        switch category {
        case .selfReflection: return "What’s one belief you changed this year, and what sparked it?"
        case .memories:       return "What memory from the last five years makes you smile instantly?"
        case .relationships:  return "Who has quietly influenced you the most, and how?"
        case .goals:          return "Which goal this month scares you a little (in a good way), and why?"
        case .gratitude:      return "What small kindness from someone recently made your day better?"
        case .wouldYouRather: return "Would you rather be able to fly or time travel?"
        }
    }
}

/// (Optional) Real OpenAI implementation placeholder
/// Replace YOUR_OPENAI_KEY and endpoint/body as needed when you’re ready
struct OpenAIPromptService: PromptServiceType {
    let apiKey: String
    func generateQuestion(for category: QuestionCategory) async throws -> String {
        // TODO: Implement with URLSession to OpenAI Chat Completions.
        // Return a single-sentence question.
        throw NSError(domain: "OpenAI", code: -1,
                      userInfo: [NSLocalizedDescriptionKey: "Not implemented. Using MockPromptService for now."])
    }
}
