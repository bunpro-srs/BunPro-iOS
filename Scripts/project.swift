#!/usr/bin/env beak run --path

// MARK: - Script Dependencies
// beak: kareman/SwiftShell @ .upToNextMajor(from: "4.1.2")
// beak: onevcat/Rainbow @ .upToNextMajor(from: "3.1.2")

import Foundation
import Rainbow
import SwiftShell

// MARK: - Runnable Tasks
/// Installs all tools and dependencies required to build the project.
public func install() throws {
    try execute(bash: "tools install")
    try openXcodeProject()
}

// MARK: - Helpers
private func execute(bash command: String) throws {
    print("⏳ Executing '\(command.italic.lightYellow)'".bold)
    try runAndPrint(bash: command)
}

private func openXcodeProject() throws {
    let xcodeWorkspaces = run(bash: "find . -d 1 -regex '.*\\.xcworkspace' -type d").stdout.components(separatedBy: .newlines).filter { !$0.isEmpty }
    let xcodeProjects = run(bash: "find . -d 1 -regex '.*\\.xcodeproj' -type d").stdout.components(separatedBy: .newlines).filter { !$0.isEmpty }

    if let workspacePath = xcodeWorkspaces.first {
        try execute(bash: "open \(workspacePath)")
    } else if let projectPath = xcodeProjects.first {
        try execute(bash: "open \(projectPath)")
    } else {
        print("Could not find any Xcode Project for automatic opening.")
    }
}
