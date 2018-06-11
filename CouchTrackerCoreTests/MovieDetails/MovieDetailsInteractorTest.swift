import XCTest
import RxSwift
import RxTest
import TraktSwift
import TMDBSwift
@testable import CouchTrackerCore

final class MovieDetailsInteractorTest: XCTestCase {

	private let scheduler: TestScheduler = TestScheduler(initialClock: 0)
	private var observer: TestableObserver<MovieEntity>!
	private var imagesObserver: TestableObserver<ImagesEntity>!
	private var disposable: Disposable?

	override func setUp() {
		super.setUp()

		observer = scheduler.createObserver(MovieEntity.self)
		imagesObserver = scheduler.createObserver(ImagesEntity.self)
	}

	override func tearDown() {
		observer = nil
		disposable?.dispose()
		super.tearDown()
	}

	func testMovieDetailsInteractor_initWithDefaultScheduler() {
		let movie = TraktEntitiesMock.createMovieMock(for: "the-dark-knight-2008")
		let repository = MovieDetailsStoreMock(movie: movie)
		let genreRepository = GenreRepositoryMock()
		let imageRepository = imageRepositoryMock
		let interactor = MovieDetailsService(repository: repository, genreRepository: genreRepository,
																				imageRepository: imageRepository, movieIds: movie.ids)

		XCTAssertNotNil(interactor)
	}

	func testMovieDetailsInteractor_fetchImagesReceivesEmptyData_emitsOnCompleted() {
		let movie = TraktEntitiesMock.createMovieMock(for: "the-dark-knight-2008")
		let repository = MovieDetailsStoreMock(movie: movie)
		let genreRepository = GenreRepositoryMock()
		let imageRepository = imageRepositoryMock

		let json = "{\"trakt\": 23,\"slug\": \"1992-23\",\"imdb\": \"tt0468569\",\"tmdb\": null}".data(using: .utf8)!

		let movieIds = try! JSONDecoder().decode(MovieIds.self, from: json)

		let interactor = MovieDetailsService(repository: repository, genreRepository: genreRepository,
																				imageRepository: imageRepository, movieIds: movieIds)

		disposable = interactor.fetchImages().asObservable().subscribe(imagesObserver)

		scheduler.start()

		let events: [Recorded<Event<ImagesEntity>>] = [completed(0)]

		XCTAssertEqual(imagesObserver.events, events)
	}

	func testMovieDetailsInteractor_fetchImagesReceivesData_emitsImagesAndOnCompleted() {
		let movie = TraktEntitiesMock.createMovieMock(for: "the-dark-knight-2008")
		let repository = MovieDetailsStoreMock(movie: movie)
		let genreRepository = GenreRepositoryMock()
		let imageRepository = imageRepositoryRealMock

		let interactor = MovieDetailsService(repository: repository, genreRepository: genreRepository,
																				imageRepository: imageRepository, movieIds: movie.ids)

		disposable = interactor.fetchImages().asObservable().subscribe(imagesObserver)

		scheduler.start()

		let backdrops = [ImageEntity(link: "https:/image.tmdb.org/t/p/w780/fCayJrkfRaCRCTh8GqN30f8oyQF.jpg",
																width: 1280, height: 720, iso6391: nil, aspectRatio: 1.77777777777778,
																voteAverage: 0, voteCount: 0)]

		let posters = [ImageEntity(link: "https:/image.tmdb.org/t/p/w780/fpemzjF623QVTe98pCVlwwtFC5N.jpg",
																width: 1200, height: 1800, iso6391: "en", aspectRatio: 0.666666666666667,
																voteAverage: 0, voteCount: 0)]

		let expectedImageEntity = ImagesEntity(identifier: 550, backdrops: backdrops, posters: posters, stills: [ImageEntity]())

		let events: [Recorded<Event<ImagesEntity>>] = [next(0, expectedImageEntity), completed(0)]

		XCTAssertEqual(imagesObserver.events, events)
	}

	func testMovieDetailsInteractor_fetchSuccessWithEmptyData_andEmitsOnlyOnCompleted() {
		let movie = TraktEntitiesMock.createMovieMock(for: "the-dark-knight-2008")
		let repository = MovieDetailsStoreMock(movie: TraktEntitiesMock.createMovieDetailsMock())
		let genreRepository = GenreRepositoryMock()
		let imageRepository = imageRepositoryMock
		let interactor = MovieDetailsService(repository: repository, genreRepository: genreRepository,
																				imageRepository: imageRepository, movieIds: movie.ids)

		disposable = interactor.fetchDetails().subscribe(observer)

		scheduler.start()

		let events: [Recorded<Event<MovieEntity>>] = [completed(0)]

		XCTAssertEqual(observer.events, events)
	}

	func testMovieDetailsInteractor_fetchSuccessDetails_andEmitsDetailsAndOnCompleted() {
		let movie = TraktEntitiesMock.createMovieDetailsMock()
		let repository = MovieDetailsStoreMock(movie: movie)
		let genreRepository = GenreRepositoryMock()
		let interactor = MovieDetailsService(repository: repository, genreRepository: genreRepository,
																				imageRepository: imageRepositoryRealMock,
																				movieIds: movie.ids)

		disposable = interactor.fetchDetails().subscribe(observer)

		scheduler.start()

		let genres = try! JSONDecoder().decode([Genre].self, from: Genres.list(.movies).sampleData)
		let moviesGenre = genres.filter { movie.genres?.contains($0.slug) ?? false }

		let expectedMovie = MovieEntityMapper.entity(for: movie, with: moviesGenre)

		let events: [Recorded<Event<MovieEntity>>] = [next(0, expectedMovie), completed(0)]

		XCTAssertEqual(observer.events, events)
	}

	func testMoviesDetailsInteractor_fetchFailure_andEmitsOnlyOnError() {
		let connectionError = MovieDetailsError.noConnection("There is no connection active")
		let repository = ErrorMovieDetailsStoreMock(error: connectionError)
		let genreRepository = GenreRepositoryMock()
		let movieIds = TraktEntitiesMock.createMovieDetailsMock().ids
		let interactor = MovieDetailsService(repository: repository, genreRepository: genreRepository,
																				imageRepository: imageRepositoryMock,
																				movieIds: movieIds)

		disposable = interactor.fetchDetails().subscribe(observer)

		scheduler.start()

		let events: [Recorded<Event<MovieEntity>>] = [error(0, connectionError)]

		XCTAssertEqual(observer.events, events)

		XCTAssertEqual(observer.events[0].value.error as! MovieDetailsError, connectionError)
	}
}