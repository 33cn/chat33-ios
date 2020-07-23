//
//  SocketMessageUpvote.swift
//  IMSDK
//
//  Created by .. on 2019/11/20.
//

import UIKit
import SwiftyJSON
import RxSwift

enum SocketMessageUpvoteState: Int {
    case none = 0           //未打赏 未点赞
    case admire = 1         //已点赞
    case reward = 2         //已打赏
    case admireReward = 3   //点赞打赏
}

class SocketMessageUpvote: NSObject {
    private(set) var admire = 0
    private(set) var reward = 0
    private(set) var stateForMe = SocketMessageUpvoteState.none //自己是否打赏 是否点赞
    
    var upvoteSubject = BehaviorSubject<(admire: Int, reward: Int, stateForMe: SocketMessageUpvoteState)?>(value: nil)

    init(json: JSON? = nil) {
        super.init()
        if let admire = json?["like"].int,
            let reward = json?["reward"].int,
            let state = json?["state"].int {
            self.admire = admire
            self.reward = reward
            self.stateForMe = SocketMessageUpvoteState.init(rawValue: state) ?? .none
            DispatchQueue.main.async {
                self.upvoteSubject.onNext((self.admire, self.reward, self.stateForMe))
            }
        }
    }
    
    func set(admire: Int, reward: Int, stateForMe: SocketMessageUpvoteState) {
        guard self.admire != admire || self.reward != reward  || self.stateForMe != stateForMe else { return }
        self.admire = admire
        self.reward = reward
        self.stateForMe = stateForMe
        DispatchQueue.main.async {
            self.upvoteSubject.onNext((self.admire, self.reward, self.stateForMe))
        }
    }
    
    func jsonString() -> String {
        return JSON.init(["like" : self.admire, "reward": self.reward, "state": self.stateForMe.rawValue]).rawString() ?? ""
    }
}
