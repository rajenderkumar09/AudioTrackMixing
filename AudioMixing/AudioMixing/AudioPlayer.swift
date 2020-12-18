//
//  AudioPlayer.swift
//  AudioMixing
//
//  Created by Rajender Sharma on 17/12/20.
//  Copyright © 2020 Rajender Sharma. All rights reserved.
//

import Foundation
import AVFoundation

class AudioPlayer {

	let session = AVAudioSession.sharedInstance()
	
    var audioFile:[AVAudioFile] = [AVAudioFile]()
    var engine:AVAudioEngine
    var playerNodes = [AVAudioPlayerNode]()
    var mixer: AVAudioMixerNode
    var timer: Timer!
    var volumeTimer: Timer!

	//Current Playing Index
    var index:Int = 0

	/* Returns current AVPlayer */
	var currentPlayer: AVAudioPlayerNode {
	   return self.playerNodes[self.index]
	}

	/**
		Previous Plaer node
	*/
	var previousPlayer: AVAudioPlayerNode? {
		if self.index > 0 {
			return self.playerNodes[self.index-1]
		} else {
			return nil
		}
	}

	var currentFile: AVAudioFile {
		return self.audioFile[index]
	}
	/**
		Duration for Mixing, Default is 5
	*/
	var duration:Int = 5

    init (_ urls: [URL]) {
        engine = AVAudioEngine()
        mixer = AVAudioMixerNode()

		urls.forEach { (url) in
			self.audioFile.append(try! AVAudioFile(forReading: url))
		}
    }

	func setupPlayer() {
		if playerNodes.count > index {
			self.playerNodes.append(currentPlayer)
		} else {
			let player = AVAudioPlayerNode()
			self.playerNodes.append(player)
		}
	}

    func start() {
		self.setupPlayer()
		engine.attach(self.currentPlayer)
        engine.attach(mixer)

		engine.connect(self.currentPlayer, to:mixer , format: nil)
        engine.connect(mixer, to:engine.outputNode , format: nil)

		self.currentPlayer.scheduleFile(self.currentFile, at: nil, completionHandler: nil)
		do {

			try session.setCategory(AVAudioSession.Category.playAndRecord, options: [.mixWithOthers, .defaultToSpeaker])
			try session.setActive(true)

			//Start Engine and Play the audio track
			try engine.start()
			self.currentPlayer.volume = 0.1
			self.currentPlayer.play()
			self.startObserver()
			self.volumeTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true, block: { (timer) in

				let volumeInterval = 0.1
				//Decrease volume of prevoius player
				if let player = self.previousPlayer {
					let volumeInterval = 0.1
					let currentVolume = player.volume
					let newValue = max(Double(currentVolume) - volumeInterval, 0.0);
					player.volume = Float(newValue);
				}
				let currentVolume = self.currentPlayer.volume
				let newValue = max(Double(currentVolume) + volumeInterval, 1.0);
				self.currentPlayer.volume = Float(newValue);
				if (newValue == 1.0) {
					timer.invalidate()
				}
			})
		} catch  {
			print("Error: \(error.localizedDescription)")
		}
    }

	func startObserver() {
		self.timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) {[unowned self] timer in

			guard let nodeTime = self.currentPlayer.lastRenderTime,
				let playerTime = self.currentPlayer.playerTime(forNodeTime: nodeTime) else {
				return
			}
			let secs = Double(playerTime.sampleTime) / playerTime.sampleRate
			let length = self.currentFile.duration

			if secs >= Double(length) - Double(self.duration) {
				print(secs)
				print("Mix with other")

				self.removeObserver()
				if self.index >= self.audioFile.count-1 {
					self.index = 0
				} else {
					self.index += 1
				}
				self.start()
			}
        }
	}

	func removeObserver() {
		self.timer.invalidate()
		self.timer = nil
	}
}

extension AVAudioFile{

    var duration: TimeInterval{
        let sampleRateSong = Double(processingFormat.sampleRate)
        let lengthSongSeconds = Double(length) / sampleRateSong

        return lengthSongSeconds
    }

}
