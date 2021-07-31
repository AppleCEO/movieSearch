//
//  MovieTableViewCell.swift
//  movieSearch
//
//  Created by joon-ho kil on 2021/07/29.
//

import UIKit

class MovieTableViewCell: UITableViewCell {
	@IBOutlet weak var posterImageView: UIImageView!
	@IBOutlet weak var titleLabel: UILabel!
	@IBOutlet weak var directorLabel: UILabel!
	@IBOutlet weak var actorLabel: UILabel!
	@IBOutlet weak var userRatingLabel: UILabel!
	
	override func awakeFromNib() {
		super.awakeFromNib()
		// Initialization code
	}
	
	override func setSelected(_ selected: Bool, animated: Bool) {
		super.setSelected(selected, animated: animated)
		
		// Configure the view for the selected state
	}
	
	func putData(_ movie: Movie) {
		downloadImage(from: movie.image)
		self.titleLabel.text = removeHTMLTagFrom(movie.title)
		self.directorLabel.text = Role.director.rawValue+movie.director
		self.actorLabel.text = Role.actor.rawValue+movie.actor
		self.userRatingLabel.text = Role.userRating.rawValue+movie.userRating
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
	
	override func prepareForReuse() {
		self.posterImageView.image = nil
		self.titleLabel.text = nil
		self.directorLabel.text = nil
		self.actorLabel.text = nil
		self.userRatingLabel.text = nil
	}
}
