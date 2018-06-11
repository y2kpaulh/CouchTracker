import RxSwift
import XCTest
@testable import CouchTrackerCore

final class TraktLoginPresenterTest: XCTestCase {
	private var view: TraktLoginViewMock!
	private var output: TraktLoginOutputMock!
	private var schedulers: TestSchedulers!

	override func setUp() {
		super.setUp()

		self.schedulers = TestSchedulers(initialClock: 0)
		self.view = TraktLoginViewMock()
		self.output = TraktLoginOutputMock()
	}

	override func tearDown() {
		super.tearDown()

		self.schedulers = nil
		self.view = nil
		self.output = nil
	}

	func testTraktLoginPresenter_fetchLoginURLFails_notifyOutput() {
		//Given
		let message = "Invalid Trakt parameters"
		let userInfo = [NSLocalizedDescriptionKey: message]
		let genericError = NSError(domain: "io.github.pietrocaselani", code: 50, userInfo: userInfo)
		let interactor = TraktLoginErrorInteractorMock(error: genericError)
		let presenter = TraktLoginDefaultPresenter(view: view, interactor: interactor, output: output, schedulers: schedulers)

		//When
		presenter.viewDidLoad()
		schedulers.start()

		//Then
		XCTAssertTrue(output.invokedLogInFail)
		XCTAssertEqual(output.invokedLoginFailParameters?.message, message)
	}

	func testTraktLoginPresenter_fetchLoginURLSuccess_notifyView() {
		//Given
		let url = URL(string: "https://trakt.tv/login")!
		let interactor = TraktLoginInteractorMock(traktProvider: TraktProviderMock(oauthURL: url))
		let presenter = TraktLoginDefaultPresenter(view: view, interactor: interactor, output: output, schedulers: schedulers)

		//When
		presenter.viewDidLoad()
		schedulers.start()

		//Then
		XCTAssertTrue(view.invokedLoadLogin)
		XCTAssertEqual(view.invokedLoadLoginParameters?.url, url)
	}
}