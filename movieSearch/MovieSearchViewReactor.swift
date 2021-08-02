//
//  MovieSearchReactor.swift
//  movieSearch
//
//  Created by joon-ho kil on 2021/07/28.
//

import Foundation

import ReactorKit
import RxCocoa
import RxSwift

final class MovieSearchViewReactor: Reactor {
	enum Action {
		case updateQuery(String?)
		case loadNextPage
	}
	
	enum Mutation {
		case setQuery(String?)
		case setMovies([Movie], nextPage: Int?)
		case appendMovies([Movie], nextPage: Int?)
		case setLoadingNextPage(Bool)
	}
	
	struct State {
		var query: String?
		var movies: [Movie] = []
		var nextPage: Int?
		var isLoadingNextPage: Bool = false
	}
	
	let initialState = State()
	
	func mutate(action: Action) -> Observable<Mutation> {
		switch action {
		case let .updateQuery(query):
			return Observable.concat([
				// 1) set current state's query (.setQuery)
				Observable.just(Mutation.setQuery(query)),
				
				// 2) call API and set repos (.setRepos)
				self.search(query: query, page: 0)
					// cancel previous request when the new `.updateQuery` action is fired
					.takeUntil(self.action.filter(Action.isUpdateQueryAction))
					.map { Mutation.setMovies($0, nextPage: $1) },
			])
			
		case .loadNextPage:
			guard !self.currentState.isLoadingNextPage else { return Observable.empty() } // prevent from multiple requests
			guard let page = self.currentState.nextPage else { return Observable.empty() }
			return Observable.concat([
				// 1) set loading status to true
				Observable.just(Mutation.setLoadingNextPage(true)),
				
				// 2) call API and append repos
				self.search(query: self.currentState.query, page: page)
					.takeUntil(self.action.filter(Action.isUpdateQueryAction))
					.map { Mutation.appendMovies($0, nextPage: $1) },
				
				// 3) set loading status to false
				Observable.just(Mutation.setLoadingNextPage(false)),
			])
		}
	}
	
	func reduce(state: State, mutation: Mutation) -> State {
		switch mutation {
		case let .setQuery(query):
			var newState = state
			newState.query = query
			return newState
			
		case let .setMovies(movies, nextPage):
			var newState = state
			newState.movies = movies
			newState.nextPage = nextPage
			return newState
			
		case let .appendMovies(movies, nextPage):
			var newState = state
			newState.movies.append(contentsOf: movies)
			newState.nextPage = nextPage
			return newState
			
		case let .setLoadingNextPage(isLoadingNextPage):
			var newState = state
			newState.isLoadingNextPage = isLoadingNextPage
			return newState
		}
	}
	
	private func url(for query: String?, page: Int) -> URL? {
		guard let query = query, !query.isEmpty else { return nil }
		guard let eoncodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else { return nil }
		let start = page * 10 + 1
		return URL(string: "https://openapi.naver.com/v1/search/movie.json?query=\(eoncodedQuery)&start=\(start)")
	}
	
	private func search(query: String?, page: Int) -> Observable<([Movie], nextPage: Int?)> {
		let emptyResult: ([Movie], Int?) = ([], nil)
		guard let url = self.url(for: query, page: page) else { return .just(emptyResult) }
		var request = URLRequest(url: url)
		request.httpMethod = "GET"
		request.setValue("FU2L100PvGKdZqxBo9y7", forHTTPHeaderField:"X-Naver-Client-Id")
		request.setValue("HhgDo2janG", forHTTPHeaderField:"X-Naver-Client-Secret")
		return URLSession.shared.rx.data(request: request)
			.map { data -> ([Movie], Int?) in
				let decoder: JSONDecoder = JSONDecoder()
				let model = try decoder.decode(MovieSearchModel.self, from: data)
				guard let movies = model.movies else { return emptyResult }
				let nextPage = movies.isEmpty ? nil : page + 1
				return (movies, nextPage)
			}
			.do(onError: { error in
				if case let .some(.httpRequestFailed(response, _)) = error as? RxCocoaURLError, response.statusCode == 403 {
					print("⚠️ Naver API rate limit exceeded. Wait for 60 seconds and try again.")
				}
			})
			.catchErrorJustReturn(emptyResult)
	}
}

extension MovieSearchViewReactor.Action {
	static func isUpdateQueryAction(_ action: MovieSearchViewReactor.Action) -> Bool {
		if case .updateQuery = action {
			return true
		} else {
			return false
		}
	}
}
