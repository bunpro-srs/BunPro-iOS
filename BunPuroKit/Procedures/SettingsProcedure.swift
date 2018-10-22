//
//  SettingsProcedure.swift
//  BunPuroKit
//
//  Created by Andreas Braun on 07.12.17.
//  Copyright © 2017 Andreas Braun. All rights reserved.
//

import Foundation
import ProcedureKit
import ProcedureKitNetwork

public final class SetSettingsProcedure: GroupProcedure {
    
    public struct Settings {
        public var furigana: FuriganaMode
        public var english: Active
        public var bunnyMode: State
        
        fileprivate var queryItems: [URLQueryItem] {
            return [
                URLQueryItem(name: "user[furigana]", value: furigana.rawValue),
                URLQueryItem(name: "user[hide_english]", value: english.rawValue),
                URLQueryItem(name: "user[bunny_mode]", value: bunnyMode.rawValue)
            ]
        }
        
        public init(furigana: FuriganaMode, english: Active, bunnyMode: State) {
            self.furigana = furigana
            self.english = english
            self.bunnyMode = bunnyMode
        }
    }
    
    private var _networkProcedure: NetworkProcedure<NetworkDataProcedure>!
    private var _userProcedure: UserProcedure!
    
    public let completion: ((BPKAccount?, Error?) -> Void)
    public let presentingViewController: UIViewController
    public let settings: Settings
    
    public init(presentingViewController: UIViewController, settings: Settings, completion: @escaping (BPKAccount?, Error?) -> Void) {
        
        self.completion = completion
        self.presentingViewController = presentingViewController
        self.settings = settings
        
        super.init(operations: [])
        
        add(condition: LoggedInCondition(presentingViewController: presentingViewController))
    }
    
    override public func execute() {
        
        guard !isCancelled else { return }
        
        var components = URLComponents(string: "https://bunpro.jp/api/v2/user/edit")!
        components.queryItems = settings.queryItems
        var request = URLRequest(url: components.url!)
        request.httpMethod = "POST"
        
        request.setValue("Token token=\(Server.token!)", forHTTPHeaderField: "Authorization")
        
        _networkProcedure = NetworkProcedure(resilience: DefaultNetworkResilience(requestTimeout: nil)) { NetworkDataProcedure(session: URLSession.shared, request: request) }
        _userProcedure = UserProcedure(presentingViewController: presentingViewController, completion: completion)
        _userProcedure.addDependency(_networkProcedure)
        
        add(child: _networkProcedure)
        add(child: _userProcedure)
        
        super.execute()
    }
}
