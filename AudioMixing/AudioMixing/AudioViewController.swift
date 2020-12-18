//
//  AudioViewController.swift
//  AudioMixing
//
//  Created by Rajender Sharma on 15/12/20.
//  Copyright © 2020 Rajender Sharma. All rights reserved.
//

import UIKit
import AVFoundation


class AudioViewController: UIViewController {
    var audioEngine: AVAudioEngine = AVAudioEngine()
    var audioPlayer: AVAudioPlayerNode = AVAudioPlayerNode()
	let speedControl = AVAudioUnitVarispeed()
	let pitchControl = AVAudioUnitTimePitch()

	/**
		Default Duration for Mixing
	*/
	var duration:Int = 5

	/**
		Array for holding all tracks passed from RootViewController
	*/
	var tracks: [Track]!

	override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
		configureView()
    }

	/**
		Method: configure view and set UI objects to default settings/options
	*/
	private func configureView() {
		self.title = "Audio Engine"

		// Setup and start main player
		self.tracks.enumerated().forEach { (index, track) in
			guard let path = Bundle.main.path(forResource: track.fileName, ofType: track.type), let trackURL:URL = URL(fileURLWithPath: path) as? URL else {
				return
			}
			do {
				try self.play(trackURL)
			} catch {
				print("Error: \(error.localizedDescription)")
			}
		}
	}

	func play(_ url: URL) throws {
		// 1: load the file
		let file = try AVAudioFile(forReading: url)

		// 2: create the audio player
		let audioPlayer = AVAudioPlayerNode()

		// 3: connect the components to our playback engine
		audioEngine.attach(audioPlayer)
		audioEngine.attach(pitchControl)
		audioEngine.attach(speedControl)

		// 4: arrange the parts so that output from one is input to another
		audioEngine.connect(audioPlayer, to: speedControl, format: nil)
		audioEngine.connect(speedControl, to: pitchControl, format: nil)
		audioEngine.connect(pitchControl, to: audioEngine.mainMixerNode, format: nil)

		// 5: prepare the player to play its file from the beginning
		audioPlayer.scheduleFile(file, at: nil)

		// 6: start the engine and player
		try audioEngine.start()
		audioPlayer.play()
	}
}
