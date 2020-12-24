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
    var playerNodes = [AVAudioPlayerNode(), AVAudioPlayerNode()]
    var mixer: AVAudioMixerNode
    var timer: Timer!
    var volumeTimer: Timer!

	//Current Playing Index
    var index:Int = 0
	var playingCopy = false

	/* Returns current AVPlayer */
	var currentPlayer: AVAudioPlayerNode {
		return self.playingCopy ? self.playerNodes.last! : self.playerNodes.first!
	}

	/**
		Previous Plaer node
	*/
	var previousPlayer: AVAudioPlayerNode? {
		return self.playingCopy ? self.playerNodes.first : self.playerNodes.last
	}

	var currentFile: AVAudioFile {
		return self.audioFile[index]
	}
	/**
		Duration for Mixing, Default is 5
	*/
	var duration:Int

	init (_ urls: [URL], duration:Int=5) {
        engine = AVAudioEngine()
        mixer = AVAudioMixerNode()
		self.duration = duration
		urls.forEach { (url) in
			self.audioFile.append(try! AVAudioFile(forReading: url))
		}
    }

	func setupPlayer() {
		if playerNodes.count-1 < index {
			let player = AVAudioPlayerNode()
			self.playerNodes.append(player)
			//self.playerNodes.append(currentPlayer)
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
			self.fadeInOutAudio()
		} catch  {
			print("Error: \(error.localizedDescription)")
		}
    }

	/**
		Method used to fade in/fade out audio volumes, Timer is used to perform the action.
	*/
	func fadeInOutAudio() {
		self.volumeTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true, block: { [unowned self] (timer) in

			let volumeInterval = 1.0 / Double(self.duration)
			//Decrease volume of prevoius player
			if let player = self.previousPlayer {
				let currentVolume = player.volume
				let newValue = max(Double(currentVolume) - volumeInterval, 0.0);
				player.volume = Float(newValue);
			}
			let currentVolume = self.currentPlayer.volume
			let newValue = min(Double(currentVolume) + volumeInterval, 1.0);
			self.currentPlayer.volume = Float(newValue);
			if (newValue == 1.0) {
				timer.invalidate()
				self.cleanUpAndDetachPlayerNode()
			}
		})
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
				// Invert current player
				self.playingCopy = !self.playingCopy
				self.start()
			}
        }
	}

	func removeObserver() {
		self.timer.invalidate()
		self.timer = nil
	}

	func cleanUpAndDetachPlayerNode() {
		if let player = self.previousPlayer {
			player.stop()
			self.engine.detach(player)
			//self.playerNodes.remove(at: self.index-1)
		}
	}
}

extension AVAudioFile{

    var duration: TimeInterval{
        let sampleRateSong = Double(processingFormat.sampleRate)
        let lengthSongSeconds = Double(length) / sampleRateSong

        return lengthSongSeconds
    }

}
