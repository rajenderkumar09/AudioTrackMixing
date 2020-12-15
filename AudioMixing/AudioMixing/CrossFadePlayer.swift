//
//  CrossFadePlayer.swift
//  Tracks
//
//  Created by Rajender Sharma on 08/12/20.
//  Copyright © 2020 Rajender Sharma. All rights reserved.
//

import UIKit
import AVFoundation

class CrossFadePlayer: NSObject {

	let session = AVAudioSession.sharedInstance()
    // Duplicate players to handle optional cross-fading.
	var playerQueue:[AVPlayer] = []

	//Array of Tracks to play
	var items: [Track]

	//Current Playing Index
    var index:Int

    // Duration for overlapping cross-fade
    var crossFadeDuration: Double

	var timeObserverToken: Any?

    /* Returns current AVPlayer */
    var currentPlayer: AVPlayer {
		return self.playerQueue[self.index]
    }

	init(items: [Track], fadeDuration:Double, index:Int) {

		//Set fading duration
		self.crossFadeDuration = fadeDuration
		self.items = items
		self.index = index
		super.init()

        // Setup and start main player
		self.items.enumerated().forEach { (index, track) in
			guard let path = Bundle.main.path(forResource: track.fileName, ofType: track.type), let trackURL:URL = URL(fileURLWithPath: path) as? URL else {
				return
			}
			let player = AVPlayer(playerItem: AVPlayerItem(url: trackURL))
			self.playerQueue.append(player)
		}

        // Add volume ramps
        self.addVolumeRamps(with: self.crossFadeDuration)

        // Add time observer
        self.addPeriodicTimeObserver(for: self.currentPlayer)

		//Set AVAudioSession
		do {
			try session.setCategory(AVAudioSession.Category.playback)
			try session.setActive(true)
		} catch  {
			print("Error: \(error)")
		}

        // Start playback
        self.currentPlayer.play()
    }

    /// Add volume ramps for all players in queue.
    fileprivate func addVolumeRamps(with duration: Double) {
        for player in self.playerQueue {
            player.currentItem?.addFadeInOut(duration: duration)
        }
    }

    /// Add periodic time observer for current player.
    fileprivate func addPeriodicTimeObserver(for player: AVPlayer) {
        self.timeObserverToken = self.currentPlayer.addPeriodicTimeObserver(forInterval: CMTimeMakeWithSeconds(1, preferredTimescale: CMTimeScale(NSEC_PER_SEC)), queue: .main) { [weak self] (currentTime) in
			print(currentTime)

            if let currentItem = self?.currentPlayer.currentItem, currentItem.status == .readyToPlay, let crossFadeDuration = self?.crossFadeDuration {
                let totalDuration = currentItem.asset.duration

                /**
                    Logic for Looping
                 */
                // Start cross-fade logic towards end of playback
                if (CMTimeCompare(currentTime, totalDuration - CMTimeMakeWithSeconds(crossFadeDuration, preferredTimescale: CMTimeScale(NSEC_PER_SEC))) > 0) {

                    // Handle crossfade
                    self?.handleCrossFade()
                }
            }
        }
    }

    /// Cycles between players in Queue
    fileprivate func handleCrossFade() {

		print("Cross Fade")
        // Remove current player observer (if any)
        self.removePeriodicTimeObserver(for: self.currentPlayer)

        // Invert current player
       if self.index < playerQueue.count-1 {
			self.index += 1
		} else {
			print("Reached to End of Queue, Looping to start")
			self.index = 0
		}
        // Start observing inverted player
        self.addPeriodicTimeObserver(for: self.currentPlayer)

        // Play
        self.currentPlayer.seek(to: .zero)
        self.currentPlayer.play()
    }

    /// Remove periodic time observer
    fileprivate func removePeriodicTimeObserver(for player: AVPlayer) {
        if let timeObserverToken = timeObserverToken {
            player.removeTimeObserver(timeObserverToken)
            self.timeObserverToken = nil
        }
    }
}


extension AVPlayerItem {
	// Applies a fade in and out
	func addFadeInOut(duration: TimeInterval = 1.0) {
		let params = AVMutableAudioMixInputParameters(track: self.asset.tracks.first! as AVAssetTrack)

		// Specifies time range from beginning with duration as specified
		let timeRange = CMTimeRangeMake(start: CMTimeMakeWithSeconds(0, preferredTimescale: CMTimeScale(NSEC_PER_SEC)), duration: CMTimeMakeWithSeconds(duration, preferredTimescale: CMTimeScale(NSEC_PER_SEC)))

		// Specifies time range from end of track minus the specified duration. Total time - duration.
		 let timeRangeTowardsEnd = CMTimeRangeMake(start: CMTimeMakeWithSeconds(CMTimeGetSeconds(self.asset.duration) - duration, preferredTimescale: CMTimeScale(NSEC_PER_SEC)), duration: CMTimeMakeWithSeconds(duration, preferredTimescale: CMTimeScale(NSEC_PER_SEC)))

		// Ramp up from volume 0 to volume 1 at specified timeRange
		params.setVolumeRamp(fromStartVolume: 0, toEndVolume: 1, timeRange: timeRange)
		params.setVolumeRamp(fromStartVolume: 1, toEndVolume: 0, timeRange: timeRangeTowardsEnd)

		let mix = AVMutableAudioMix()
		mix.inputParameters = [params]

		self.audioMix = mix
	}
}
