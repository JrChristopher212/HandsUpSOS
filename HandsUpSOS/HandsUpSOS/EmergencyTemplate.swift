//
//  EmergencyTemplate.swift
//  HandsUpSOS
//
//  Created by Jedda Tuuta on 10/8/2025.
//

import Foundation

struct EmergencyTemplate {
    let emoji: String
    let title: String
    let message: String
    
    static let campingTemplates: [EmergencyTemplate] = [
        EmergencyTemplate(
            emoji: "🏕️",
            title: "Lost While Hiking",
            message: "I am lost while hiking and need immediate assistance. I may be injured or unable to find my way back to the trail."
        ),
        EmergencyTemplate(
            emoji: "🦴",
            title: "Broken Bone/Injury",
            message: "I have suffered a serious injury (broken bone, sprain, or other injury) and cannot move safely. I need medical assistance."
        ),
        EmergencyTemplate(
            emoji: "🐍",
            title: "Snake Bite",
            message: "I have been bitten by a snake. I need immediate medical attention and help getting to safety."
        ),
        EmergencyTemplate(
            emoji: "🌊",
            title: "Water Emergency",
            message: "I am in trouble near water (river, lake, ocean) and need immediate rescue assistance."
        ),
        EmergencyTemplate(
            emoji: "🔥",
            title: "Fire Emergency",
            message: "There is a fire emergency in my area. I need help evacuating or the fire needs immediate attention."
        ),
        EmergencyTemplate(
            emoji: "🌪️",
            title: "Weather Emergency",
            message: "I am caught in severe weather conditions (storm, flood, extreme heat/cold) and need immediate assistance."
        ),
        EmergencyTemplate(
            emoji: "🚑",
            title: "Medical Emergency",
            message: "I am experiencing a medical emergency (chest pain, difficulty breathing, severe bleeding, etc.) and need immediate medical help."
        ),
        EmergencyTemplate(
            emoji: "🚨",
            title: "General Emergency",
            message: "I am in a general emergency situation and need immediate assistance. Please help me get to safety."
        )
    ]
}
