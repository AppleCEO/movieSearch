//
//  MovieViewController.swift
//  movieSearch
//
//  Created by joon-ho kil on 2021/07/29.
//

import UIKit
import WebKit

class MovieViewController: UIViewController {
	@IBOutlet weak var posterImageView: UIImageView!
	@IBOutlet weak var directorLabel: UILabel!
	@IBOutlet weak var actorLabel: UILabel!
	@IBOutlet weak var userRatingLabel: UILabel!
	var movie: Movie?
	@IBOutlet weak var webView: WKWebView!
	
	override func viewDidLoad() {
		super.viewDidLoad()
		guard let movie = self.movie else { return }
		self.navigationItem.title = removeHTMLTagFrom(movie.title)
		downloadImage(from: movie.image)
		self.directorLabel.text = Role.director.rawValue+movie.director
		self.actorLabel.text = Role.actor.rawValue+movie.actor
		self.userRatingLabel.text = Role.userRating.rawValue+movie.userRating
		guard let link = URL(string:movie.link) else { return }
		let request = URLRequest(url: link)
		self.webView.load(request)
	}
	
	private func downloadImage(from: String) {
		guard let url = URL(string: from) else { return }
		getData(from: url) { data, response, error in
			guard let data = data, error == nil else { return }
			DispatchQueue.main.async() { [weak self] in
				self?.posterImageView.image = UIImage(data: data)
			}
		}
	}
	
	private func getData(from url: URL, completion: @escaping (Data?, URLResponse?, Error?) -> ()) {
		URLSession.shared.dataTask(with: url, completionHandler: completion).resume()
	}
	
	private func removeHTMLTagFrom(_ string: String) -> String {
		return string.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression, range: nil)
	}
}
