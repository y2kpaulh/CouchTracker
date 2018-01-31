import XCTest
import RxTest
import RxSwift
import TraktSwift

final class TrendingCacheRepositoryTest: XCTestCase {
	private let scheduler = TestScheduler(initialClock: 0)
	private let disposeBag = DisposeBag()
	private var repository: TrendingCacheRepository!
	private var moviesObserver: TestableObserver<[TrendingMovie]>!
	private var showsObserver: TestableObserver<[TrendingShow]>!

	override func setUp() {
		super.setUp()

		moviesObserver = scheduler.createObserver([TrendingMovie].self)
		showsObserver = scheduler.createObserver([TrendingShow].self)
		repository = TrendingCacheRepository(traktProvider: traktProviderMock, scheduler: scheduler)
	}

	func testFetchMoviesEmitMoviesAndComplete() {
		repository.fetchMovies(page: 0, limit: 50).subscribe(moviesObserver).disposed(by: disposeBag)

		scheduler.start()

		let expectedMovies = createTrendingMoviesMock()
		let expectedEvents: [Recorded<Event<[TrendingMovie]>>] = [next(0, expectedMovies), completed(0)]

		RXAssertEvents(moviesObserver, expectedEvents)
	}

	func testFetchShowsEmitShowsAndComplete() {
		repository.fetchShows(page: 0, limit: 50).subscribe(showsObserver).disposed(by: disposeBag)

		scheduler.start()

		let expectedShows = createTrendingShowsMock()
		let expectedEvents: [Recorded<Event<[TrendingShow]>>] = [next(0, expectedShows), completed(0)]

		RXAssertEvents(showsObserver, expectedEvents)
	}
}