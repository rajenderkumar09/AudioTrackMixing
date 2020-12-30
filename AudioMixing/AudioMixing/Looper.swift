//
//  Looper.swift
//  Tracks
//
//  Created by Rajender Sharma on 08/12/20.
//  Copyright © 2020 Rajender Sharma. All rights reserved.
//

import Foundation
import AVFoundation

class Looper: NSObject {
	var index:Int = 0
	var player: CrossFadePlayer!
	var queue: [Track]
	var fadeDuration : Double

	init(queue:[Track], fadeDuration:Double) {
		self.queue = queue
		self.fadeDuration = fadeDuration
		super.init()
		self.play(index: index)
	}

	func play(index:Int) {
		do {
			self.player = CrossFadePlayer(items: queue, fadeDuration: self.fadeDuration, index: self.index)
//			self.player = try AVAudioPlayer(contentsOf: trackURL)
//			self.player.delegate = self
//			self.player.setVolume(1, fadeDuration: 2)
//			self.player.play()
//			self.index += 1
		} catch {
			print("Error: \(error.localizedDescription)")
		}
	}

	func stop() {
		self.player.stop()
	}
}

extension Looper: AVAudioPlayerDelegate {
	func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
		
	}
}
