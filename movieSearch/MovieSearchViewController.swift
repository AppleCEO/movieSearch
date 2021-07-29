//
//  MovieSearchViewController.swift
//  movieSearch
//
//  Created by joon-ho kil on 2021/07/28.
//

import SafariServices
import UIKit

import ReactorKit
import RxCocoa
import RxSwift

class MovieSearchViewController: UIViewController, StoryboardView {
  @IBOutlet var movieTableView: UITableView!
  let searchController = UISearchController(searchResultsController: nil)

  var disposeBag = DisposeBag()

  override func viewDidLoad() {
    super.viewDidLoad()
    movieTableView.scrollIndicatorInsets.top = movieTableView.contentInset.top
    searchController.dimsBackgroundDuringPresentation = false
    navigationItem.searchController = searchController
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    UIView.setAnimationsEnabled(false)
    searchController.isActive = true
    searchController.isActive = false
    UIView.setAnimationsEnabled(true)
  }

  func bind(reactor: MovieSearchViewReactor) {
    // Action
    searchController.searchBar.rx.text
      .throttle(.milliseconds(300), scheduler: MainScheduler.instance)
      .map { Reactor.Action.updateQuery($0) }
      .bind(to: reactor.action)
      .disposed(by: disposeBag)

    movieTableView.rx.contentOffset
      .filter { [weak self] offset in
        guard let `self` = self else { return false }
        guard self.movieTableView.frame.height > 0 else { return false }
        return offset.y + self.movieTableView.frame.height >= self.movieTableView.contentSize.height - 100
      }
      .map { _ in Reactor.Action.loadNextPage }
      .bind(to: reactor.action)
      .disposed(by: disposeBag)

    // State
    reactor.state.map { $0.movies }
      .bind(to: movieTableView.rx.items(cellIdentifier: "cell")) { indexPath, movie, cell in
        guard let movieTableViewCell = cell as? MovieTableViewCell else { return }
				movieTableViewCell.putData(movie)
      }
      .disposed(by: disposeBag)

    // View
    movieTableView.rx.itemSelected
      .subscribe(onNext: { [weak self, weak reactor] indexPath in
        guard let `self` = self else { return }
        self.view.endEditing(true)
        self.movieTableView.deselectRow(at: indexPath, animated: false)
        guard let movie = reactor?.currentState.movies[indexPath.row] else { return }
        guard let url = URL(string: movie.link) else { return }
        let viewController = SFSafariViewController(url: url)
        self.searchController.present(viewController, animated: true, completion: nil)
      })
      .disposed(by: disposeBag)
  }
}
