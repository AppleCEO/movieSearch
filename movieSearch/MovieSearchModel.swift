//
//  MovieSearchModel.swift
//  movieSearch
//
//  Created by joon-ho kil on 2021/07/29.
//

import Foundation

// MARK: - MovieSearchModel
struct MovieSearchModel: Codable {
	let lastBuildDate: String?
	let total, start, display: Int?
	let movies: [Movie]?
	
	enum CodingKeys: String, CodingKey {
		case lastBuildDate = "lastBuildDate"
		case total = "total"
		case start = "start"
		case display = "display"
		case movies = "items"
	}
}

// MARK: - Item
struct Movie: Codable {
	let title: String
	let link: String
	let image: String
	let subtitle, pubDate, director, actor: String
	let userRating: String
}
