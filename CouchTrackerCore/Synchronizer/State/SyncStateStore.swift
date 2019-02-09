import RxSwift

public final class SyncStateStore: SyncStateObservable, SyncStateOutput {
  private let subject: BehaviorSubject<SyncState>

  public init(initialState: SyncState = .initial) {
    subject = BehaviorSubject<SyncState>(value: initialState)
  }

  public func observe() -> Observable<SyncState> {
    return subject.distinctUntilChanged()
  }

  public func newSyncState(state: SyncState) {
    guard let currentState = try? subject.value() else { return }

    if currentState != state {
      subject.onNext(state)
    }
  }
}
