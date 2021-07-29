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
    let items: [Item]?
}

// MARK: - Item
struct Item: Codable {
    let title: String
    let link: String
    let image: String
    let subtitle, pubDate, director, actor: String
    let userRating: String
}
