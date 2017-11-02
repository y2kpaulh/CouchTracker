import TraktSwift
import RxSwift

final class ShowEpisodeAPIRepository: ShowEpisodeRepository {
  private let trakt: TraktProvider
  private let scheduler: SchedulerType

  convenience init(trakt: TraktProvider) {
    self.init(trakt: trakt, scheduler: SerialDispatchQueueScheduler(qos: .background))
  }

  init(trakt: TraktProvider, scheduler: SchedulerType) {
    self.trakt = trakt
    self.scheduler = scheduler
  }

  func addToHistory(items: SyncItems) -> Single<SyncResponse> {
    return trakt.sync.rx.request(.addToHistory(items: items))
      .observeOn(scheduler)
      .filterSuccessfulStatusAndRedirectCodes()
      .map(SyncResponse.self)
  }

  func removeFromHistory(items: SyncItems) -> Single<SyncResponse> {
    return trakt.sync.rx.request(.removeFromHistory(items: items))
      .observeOn(scheduler)
      .filterSuccessfulStatusAndRedirectCodes()
      .map(SyncResponse.self)
  }
}
