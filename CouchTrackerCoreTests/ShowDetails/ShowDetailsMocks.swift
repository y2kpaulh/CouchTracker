@testable import CouchTrackerCore
import RxSwift
import TraktSwift

let showDetailsRepositoryMock = ShowOverviewRepositoryMock(traktProvider: createTraktProviderMock())

final class ShowOverviewRepositoryErrorMock: ShowOverviewRepository {
  private let error: Error

  init(traktProvider _: TraktProvider = createTraktProviderMock()) {
    error = NSError(domain: "io.github.pietrocaselani", code: 120)
  }

  init(traktProvider _: TraktProvider = createTraktProviderMock(), error: Error) {
    self.error = error
  }

  func fetchDetailsOfShow(with _: String, extended _: Extended) -> Single<Show> {
    return Single.error(error)
  }
}

final class ShowOverviewRepositoryMock: ShowOverviewRepository {
  private let provider: TraktProvider
  init(traktProvider: TraktProvider) {
    provider = traktProvider
  }

  func fetchDetailsOfShow(with identifier: String, extended: Extended) -> Single<Show> {
    return provider.shows.rx.request(.summary(showId: identifier, extended: extended)).map(Show.self)
  }
}

final class ShowOverviewInteractorMock: ShowOverviewInteractor {
  private let genreRepository: GenreRepository
  private let imageRepository: ImageRepository
  private let repository: ShowOverviewRepository
  private let showIds: ShowIds

  init(showIds: ShowIds, repository: ShowOverviewRepository,
       genreRepository: GenreRepository, imageRepository: ImageRepository) {
    self.showIds = showIds
    self.repository = repository
    self.genreRepository = genreRepository
    self.imageRepository = imageRepository
  }

  func fetchDetailsOfShow() -> Single<ShowEntity> {
    let genresObservable = genreRepository.fetchShowsGenres().asObservable()
    let showObservable = repository.fetchDetailsOfShow(with: showIds.slug, extended: .full).asObservable()

    return Observable.combineLatest(showObservable, genresObservable, resultSelector: { (show, genres) -> ShowEntity in
      let showGenres = genres.filter { genre -> Bool in
        show.genres?.contains(where: { $0 == genre.slug }) ?? false
      }
      return ShowEntityMapper.entity(for: show, with: showGenres)
    }).asSingle()
  }

  func fetchImages() -> Maybe<ImagesEntity> {
    guard let tmdbId = showIds.tmdb else { return Maybe.empty() }

    return imageRepository.fetchShowImages(for: tmdbId, posterSize: nil, backdropSize: nil)
  }
}
