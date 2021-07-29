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
    case setRepos([String])
    case appendRepos([String])
    case setLoadingNextPage(Bool)
  }

  struct State {
    var query: String?
    var repos: [String] = []
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
        self.search(query: query)
          // cancel previous request when the new `.updateQuery` action is fired
          .takeUntil(self.action.filter(Action.isUpdateQueryAction))
          .map { Mutation.setRepos($0) },
      ])

    case .loadNextPage:
      guard !self.currentState.isLoadingNextPage else { return Observable.empty() } // prevent from multiple requests
      guard let page = self.currentState.nextPage else { return Observable.empty() }
      return Observable.concat([
        // 1) set loading status to true
        Observable.just(Mutation.setLoadingNextPage(true)),

        // 2) call API and append repos
        self.search(query: self.currentState.query)
          .takeUntil(self.action.filter(Action.isUpdateQueryAction))
          .map { Mutation.appendRepos($0) },

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

    case let .setRepos(repos):
      var newState = state
      newState.repos = repos
      return newState

    case let .appendRepos(repos):
      var newState = state
      newState.repos.append(contentsOf: repos)
      return newState

    case let .setLoadingNextPage(isLoadingNextPage):
      var newState = state
      newState.isLoadingNextPage = isLoadingNextPage
      return newState
    }
  }

  private func url(for query: String?) -> URL? {
    guard let query = query, !query.isEmpty else { return nil }
    guard let eoncodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else { return nil }
    return URL(string: "https://openapi.naver.com/v1/search/movie.json?query=\(eoncodedQuery)")
  }

  private func search(query: String?) -> Observable<([String])> {
    let emptyResult: ([String]) = ([])
    guard let url = self.url(for: query) else { return .just(emptyResult) }
    var request = URLRequest(url: url)
    request.httpMethod = "GET"
    request.setValue("FU2L100PvGKdZqxBo9y7", forHTTPHeaderField:"X-Naver-Client-Id")
    request.setValue("HhgDo2janG", forHTTPHeaderField:"X-Naver-Client-Secret")
    return URLSession.shared.rx.data(request: request)
      .map { data -> ([String]) in
        let decoder: JSONDecoder = JSONDecoder()
        let model = try decoder.decode(MovieSearchModel.self, from: data)
        guard let items = model.items else { return emptyResult }
        let repos = items.compactMap { $0.title }
        return (repos)
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
