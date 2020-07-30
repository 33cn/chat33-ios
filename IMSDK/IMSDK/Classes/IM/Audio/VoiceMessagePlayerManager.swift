//
//  VoiceMessagePlayerManager.swift
//  IM_SocketIO_Demo
//
//  Created by Wang on 2018/5/31.
//  Copyright © 2018年 Wang. All rights reserved.
//

import UIKit
import AVFoundation
import TSVoiceConverter
import RxSwift
typealias VoicePlayHandler = ()->()

let PlayVoiceModeKey = "PlayVoiceModeKey"

enum FZMAudioPlayType {
    case playAndRecord
    case playBack
}

enum FZMVoicePalyState {
    case start
    case finish
    case failed
}

class VoiceMessagePlayerManager: NSObject {
    static let singleTon = VoiceMessagePlayerManager()
    fileprivate var player: AVAudioPlayer?
    private var isPlayingVoiceMsg: SocketMessage?
    let voicePalyStateSubject = BehaviorSubject<(String,FZMVoicePalyState)?>.init(value: nil)
    
    static func shared() -> VoiceMessagePlayerManager {
        return singleTon
    }
    fileprivate override init() {
        super.init()
        
    }
    // test player
    
    func playVoice(_ recordPath:String, suspendBlock: (()->())?) {
        do {
            IMLog("\(recordPath)")
            let player:AVAudioPlayer = try AVAudioPlayer(contentsOf: URL(fileURLWithPath: recordPath))
            player.volume = 1
            player.delegate = self
            player.numberOfLoops = 0
            player.prepareToPlay()
            player.play()
            
        } catch let error as NSError {
            IMLog("get AVAudioPlayer is fail \(error)")
        }
    }
 
    private func playVoice(_ voiceData: Data) {
        do {
            self.player = try AVAudioPlayer(data: voiceData)
            self.player?.volume = 1
            self.player?.delegate = self
            self.player?.numberOfLoops = 0
            self.player?.prepareToPlay()
            self.player?.play()
            self.voicePalyStateSubject.onNext((self.isPlayingVoiceMsg?.msgId ?? "",.start))
            UIApplication.shared.isIdleTimerDisabled = true
        } catch let error as NSError {
            IMLog("get AVAudioPlayer is fail \(error)")
        }
    }
    
    func playVoice(msg: SocketMessage) {
        self.setAudioSession()
        self.stopVoice()
        if msg.msgId == isPlayingVoiceMsg?.msgId {
            isPlayingVoiceMsg = nil
            return
        }
        isPlayingVoiceMsg = msg
        let voiceUrl = msg.body.mediaUrl
        let fileUrl = msg.body.localWavPath
        
        if FZMLocalFileClient.shared().haveFile(with: .wav(fileName: fileUrl.fileName())) {
            if let data = FZMLocalFileClient.shared().readData(fileName: .wav(fileName: fileUrl.fileName()))  {
                self.playVoice(data)
            }
        }else {
            IMOSSClient.shared().download(with: URL(string: voiceUrl)!, downloadProgressBlock: { (progress) in
                
            }) { (amrData, success) in
                if success, var amrData = amrData {
                    if msg.body.isEncryptMedia {
                        amrData = msg.decryptMedia(ciphertext: amrData)
                    }
                    guard let amrPath = FZMLocalFileClient.shared().createFile(with: .amr(fileName: voiceUrl.fileName())), let wavPath = FZMLocalFileClient.shared().createFile(with: .wav(fileName: voiceUrl.fileName())) else { return }
                    let result = FZMLocalFileClient.shared().saveData(amrData, filePath: amrPath)
                    if result {
                        let convertResult = TSVoiceConverter.convertAmrToWav(amrPath, wavSavePath: wavPath)
                        if convertResult {
                            guard let data = FZMLocalFileClient.shared().readData(fileName: .wav(fileName: wavPath.fileName())) else { return }
                            self.playVoice(data)
                        }
                    }
                }else {
                    self.voicePalyStateSubject.onNext((self.isPlayingVoiceMsg?.msgId ?? "",.failed))
                    self.stopVoice()
                }
            }
        }
    }
    
    func stopVoice() {
        self.voicePalyStateSubject.onNext((self.isPlayingVoiceMsg?.msgId ?? "",.finish))
        self.player?.stop()
        UIApplication.shared.isIdleTimerDisabled = false
    }
    
    private func setAudioSession() {
        let session = AVAudioSession.sharedInstance()
        if UserDefaults.standard.bool(forKey: PlayVoiceModeKey) {
            if #available(iOS 10.0, *) {
                try? session.setCategory(AVAudioSession.Category.playAndRecord, mode: AVAudioSession.Mode.default, options: [.allowAirPlay, .allowBluetooth])
            } else {
                // Fallback on earlier versions
            }
        }else {
            if #available(iOS 10.0, *) {
                try? session.setCategory(AVAudioSession.Category.playback, mode: AVAudioSession.Mode.default, options: [.allowAirPlay, .allowBluetooth])
            } else {
                // Fallback on earlier versions
            }
        }
        try? session.setActive(true)
    }
    
    func exchangePlayMode() {
        if UserDefaults.standard.bool(forKey: PlayVoiceModeKey) {
            UserDefaults.standard.set(false, forKey: PlayVoiceModeKey)
            UserDefaults.standard.synchronize()
        }else {
            UserDefaults.standard.set(true, forKey: PlayVoiceModeKey)
            UserDefaults.standard.synchronize()
        }
    }
    
    var playMode : Bool {
        return UserDefaults.standard.bool(forKey: PlayVoiceModeKey)
    }
    
    func vibrateAction() {
        AudioServicesPlaySystemSound(1520)
    }
    
    func alertAction() {
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
        AudioServicesPlaySystemSound(1007)
    }
    
}

extension VoiceMessagePlayerManager: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        self.stopVoice()
        if let isPlayingVoiceMsg = self.isPlayingVoiceMsg, isPlayingVoiceMsg.direction == .receive,
            let nextVoiceMsg = SocketMessage.getNextUnreadVoiceMsg(timestamp: isPlayingVoiceMsg.datetime, type: isPlayingVoiceMsg.channelType, conversationId: isPlayingVoiceMsg.conversationId)  {
            self.playVoice(msg: nextVoiceMsg)
            nextVoiceMsg.body.isRead = true
            nextVoiceMsg.save()
        } else {
            isPlayingVoiceMsg = nil
        }
        
    }
}

protocol VoicePlayerDelegate: class {
    func voiceDidStartPlay(url: String, path: String)
    func voiceDidFinishPlay(url: String, path: String)
    func voiceDidFailPlay(url: String, path: String)
}

//MARK: socket连接消息
class WeakVoicePlayerDelegate: NSObject {
    weak var delegate: VoicePlayerDelegate?
    required init(delegate: VoicePlayerDelegate?) {
        self.delegate = delegate
        super.init()
    }
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromAVAudioSessionCategory(_ input: AVAudioSession.Category) -> String {
	return input.rawValue
}
