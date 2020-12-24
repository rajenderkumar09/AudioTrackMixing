//
//  RootViewController.swift
//  Tracks
//
//  Created by Rajender Sharma on 08/12/20.
//  Copyright © 2020 Rajender Sharma. All rights reserved.
//

import UIKit
import AVFoundation


class RootViewController: UIViewController {

	var audioEngine: AudioPlayer!
	
	var looper:Looper!
	/**
		Audio Player object for playing tracks
	*/
	var audioPlayer:AVAudioPlayer = AVAudioPlayer()

	/**
		Default Duration for Mixing
	*/
	var duration:Int = 5

	/**
		Generate array of Int for duration options
	*/
	lazy var durations:[Int] = {
		var values = [Int]()
		for i in 1...20 {
			values.append(i)
		}
		return values
	}()

	/**
		Load all tracks from Bundle Plist file and Map to Track model
	*/
	var tracks: [Track] {
		if let path = Bundle.main.path(forResource: "Tracks", ofType: "plist") {
			do {
				let data = try Data(contentsOf: URL(fileURLWithPath: path))
				if let arr = try PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [AnyObject] {
					return arr.map { (object) -> Track in
						return Track(name: object["name"] as! String, fileName: object["filename"] as! String, type: object["type"] as! String)
					}
				}
			} catch {
				print("Unable to read file: \(error)")
			}
		}
		return []
	}

	/**
		Outlet of UIPickerView
	*/
	@IBOutlet weak var pickerView: UIPickerView! {
		didSet {
			pickerView.delegate = self
			pickerView.dataSource = self
			pickerView.isHidden = true
		}
	}
	/**
		Collection of UILabel for displaying track name
	*/
	@IBOutlet var trackLabel: [UILabel]! {
		didSet {
			trackLabel.forEach { (label) in
				label.text = nil
			}
		}
	}

	/**
		UIButton Outlet, displays duration of cross mixing tracks
		Tap Action will show picker for selecting duration
	*/
	@IBOutlet weak var mixingDuration: UIButton! {
		/**
			Configure Duration Button UI
		*/
		didSet {
			mixingDuration.backgroundColor = .clear
			mixingDuration.setTitle("\(duration) Seconds", for: .normal)
			mixingDuration.setTitleColor(.black, for: .normal)
		}
	}

	/**
		UIButton Outlet for playing selected tracks
	*/
	@IBOutlet weak var playButton: UIButton! {
		/**
			Configure Play Button UI
		*/
		didSet {
			playButton.layer.cornerRadius = 8.0
			playButton.layer.borderColor = UIColor.black.cgColor
			playButton.layer.borderWidth = 0.5

			playButton.backgroundColor = .systemOrange
			playButton.setTitle("PLAY", for: .normal)
			playButton.setTitleColor(.white, for: .normal)
		}
	}

	/**
	 UIButton Outlet for connecting AudioEngineViewController Screen
	*/
	@IBOutlet weak var audioEngineButton: UIButton! {
		/**
			Configure Engine Button UI
		*/
		didSet {
			audioEngineButton.layer.cornerRadius = 8.0
			audioEngineButton.layer.borderColor = UIColor.black.cgColor
			audioEngineButton.layer.borderWidth = 0.5

			audioEngineButton.setTitle("Engine", for: .normal)
			audioEngineButton.setTitleColor(.black, for: .normal)
		}
	}

	override func viewDidLoad() {
		super.viewDidLoad()
		// Do any additional setup after loading the view.
		configureView()
	}

	/**
		Method: configure view and set UI objects to default settings/options
	*/
	private func configureView() {
		self.title = "Audio Cross Fit"
		trackLabel.enumerated().forEach { (index, label) in
			let track = self.tracks[index]
			label.text = "Track \(index + 1): " + track.name
		}
	}

	/**
		Mixing Duration button action
	*/
	@IBAction func mixingDurationAction(_ sender: UIButton) {
		self.pickerView.isHidden = false
		self.pickerView.selectRow(duration, inComponent: 0, animated: false)
	}

	/**
		Play button action
	*/
	@IBAction func playTracks(_ sender: UIButton) {
		self.looper = Looper(queue: Array(tracks.prefix(4)), fadeDuration: Double(duration))
		/*
		let track = self.tracks[0]
		let path = Bundle.main.path(forResource: track.fileName, ofType:track.type)!
		let url = URL(fileURLWithPath: path)
		do {
			try AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playback)
			try AVAudioSession.sharedInstance().setActive(true)

			audioPlayer = try AVAudioPlayer(contentsOf: url)
			audioPlayer.play()
		} catch {
			// couldn't load file :(
			print("Error: \(error)")
		}
		*/
	}

	/**
		AudioEngineButton Action
	*/
	@IBAction func audioEngineAction(_ sender: UIButton) {
		// Setup and start main player
		let urls = self.tracks.prefix(4).map { (track) -> URL in
			guard let path = Bundle.main.path(forResource: track.fileName, ofType: track.type), let trackURL:URL = URL(fileURLWithPath: path) as? URL else {
				return URL(string: "")!
			}
			return trackURL
		}
		self.audioEngine = AudioPlayer(urls, duration: self.duration)
		self.audioEngine.start()
		/*
		let audioEngineVC = AudioViewController(nibName: "AudioViewController", bundle: nil)
		audioEngineVC.tracks = self.tracks
		audioEngineVC.duration = self.duration
		self.navigationController?.pushViewController(audioEngineVC, animated: true)
		*/
	}
}

extension RootViewController {
	/**
		Dismiss or Hide Picker view
	*/
	override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
		self.pickerView.isHidden = true
	}
}

/**
	Extension for configuring UIPickerViewDataSource and UIPickerViewDelegate methods
*/
extension RootViewController : UIPickerViewDelegate, UIPickerViewDataSource {
	func numberOfComponents(in pickerView: UIPickerView) -> Int {
		return 1
	}

	func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
		return durations.count
	}

	func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
		return "\(durations[row]) Seconds"
	}

	func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
		duration = durations[row]
		self.mixingDuration.setTitle("\(duration) Seconds", for: .normal)
	}
}

