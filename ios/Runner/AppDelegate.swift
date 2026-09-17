import Flutter
import UIKit
import AVFoundation
import UserNotifications
#if canImport(AlarmKit)
import AlarmKit
import AppIntents
import SwiftUI
#endif

@main
@objc class AppDelegate: FlutterAppDelegate {
    private var channel: FlutterMethodChannel?
    private var recorder: AVAudioRecorder?
    private var player: AVAudioPlayer?
    private static weak var prayerDelegate: AppDelegate?
    private static let pendingPrayerKey = "pending_open_prayer"
    private var prayerBridgeReady = false
    private let center = UNUserNotificationCenter.current()

    override func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        GeneratedPluginRegistrant.register(with: self)
        let controller = window?.rootViewController as! FlutterViewController
        channel = FlutterMethodChannel(name: "cercano/device", binaryMessenger: controller.binaryMessenger)
        Self.prayerDelegate = self
        channel?.setMethodCallHandler { [weak self] call, result in
            Task { @MainActor in
                guard let self = self else { return }
                do { try await self.handle(call, result: result) }
                catch { result(FlutterError(code: "device", message: error.localizedDescription, details: nil)) }
            }
        }
        center.delegate = self
        let spanish = Locale.current.languageCode == "es"
        let snooze = UNNotificationAction(identifier: "SNOOZE", title: spanish ? "Posponer 10 min" : "Snooze 10 min", options: [])
        let pray = UNNotificationAction(identifier: "PRAY", title: spanish ? "Orar ahora" : "Pray now", options: [.foreground])
        center.setNotificationCategories([UNNotificationCategory(identifier: "PRAYER", actions: [pray,snooze], intentIdentifiers: [])])
        NotificationCenter.default.addObserver(self, selector: #selector(audioInterrupted), name: AVAudioSession.interruptionNotification, object: nil)
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    private func directory() throws -> URL {
        var url = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0].appendingPathComponent("prayers", isDirectory: true)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        var values = URLResourceValues(); values.isExcludedFromBackup = true
        try url.setResourceValues(values)
        return url
    }
    private func failure(_ message: String) -> NSError { NSError(domain: "Cercano", code: 1, userInfo: [NSLocalizedDescriptionKey: message]) }
    @MainActor private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) async throws {
        let args = call.arguments as? [String:Any] ?? [:]
        switch call.method {
        case "directory": result(try directory().path)
        case "consumeOpenPrayer":
            prayerBridgeReady = true
            let pending = UserDefaults.standard.object(forKey: Self.pendingPrayerKey) as? Int
            UserDefaults.standard.removeObject(forKey: Self.pendingPrayerKey)
            result(pending)
        case "alarmCapability":
            #if canImport(AlarmKit)
            if #available(iOS 26.0, *) { result("alarm"); return }
            #endif
            result("reminder")
        case "alarmStatus":
            #if canImport(AlarmKit)
            if #available(iOS 26.0, *) {
                result(AlarmManager.shared.authorizationState == .authorized ? "ready" : "alarm access needed"); return
            }
            #endif
            let settings = await center.notificationSettings()
            result(settings.authorizationStatus == .authorized ? "ready" : "notification access needed")
        case "settings":
            if let url = URL(string:UIApplication.openSettingsURLString) { await UIApplication.shared.open(url) }
            result(nil)
        case "schedule":
            #if canImport(AlarmKit)
            if #available(iOS 26.0, *) { try await NativePrayerAlarms.schedule(args); result(nil); return }
            #endif
            guard try await center.requestAuthorization(options: [.alert,.sound]) else { throw failure("Allow notifications in Settings to schedule reminders.") }
            let id = args["id"] as! Int
            for day in args["weekdays"] as! [Int] {
                var components = DateComponents(); components.hour = args["hour"] as? Int
                components.minute = args["minute"] as? Int; components.weekday = day % 7 + 1
                let content = reminderContent(id: id)
                try await center.add(UNNotificationRequest(identifier: "prayer-\(id)-\(day)", content: content,
                    trigger: UNCalendarNotificationTrigger(dateMatching: components, repeats: true)))
            }
            result(nil)
        case "cancel":
            let id = args["id"] as! Int
            center.removePendingNotificationRequests(withIdentifiers: (1...7).map { "prayer-\(id)-\($0)" } + ["snooze-\(id)"])
            #if canImport(AlarmKit)
            if #available(iOS 26.0, *) { try NativePrayerAlarms.cancel(id) }
            #endif
            result(nil)
        case "cancelSnooze":
            let id = args["id"] as! Int
            center.removePendingNotificationRequests(withIdentifiers: ["snooze-\(id)"])
            #if canImport(AlarmKit)
            if #available(iOS 26.0, *) { try NativePrayerAlarms.cancelSnooze(id) }
            #endif
            result(nil)
        case "cancelAll":
            center.removeAllPendingNotificationRequests(); center.removeAllDeliveredNotifications()
            #if canImport(AlarmKit)
            if #available(iOS 26.0, *) { try NativePrayerAlarms.cancelAll() }
            #endif
            result(nil)
        case "stopAlarm":
            #if canImport(AlarmKit)
            if #available(iOS 26.0, *) { try NativePrayerAlarms.stopActive() }
            #endif
            result(nil)
        case "testAlarm":
            #if canImport(AlarmKit)
            if #available(iOS 26.0, *) { try await NativePrayerAlarms.test(); result(nil); return }
            #endif
            guard try await center.requestAuthorization(options: [.alert,.sound]) else { throw failure("Allow notifications in Settings first.") }
            try await center.add(UNNotificationRequest(identifier: "prayer-test", content: reminderContent(id: 0), trigger: UNTimeIntervalNotificationTrigger(timeInterval: 10, repeats: false)))
            result(nil)
        case "record":
            let allowed = await withCheckedContinuation { (continuation: CheckedContinuation<Bool,Never>) in
                AVAudioSession.sharedInstance().requestRecordPermission { continuation.resume(returning: $0) }
            }
            guard allowed else { throw failure("Microphone access was not granted. Enable it in Settings or reflect silently.") }
            stopAudio()
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
            try session.setActive(true)
            let settings: [String:Any] = [AVFormatIDKey: kAudioFormatMPEG4AAC, AVSampleRateKey: 16000,
                AVNumberOfChannelsKey: 1, AVEncoderBitRateKey: 32000]
            let active = try AVAudioRecorder(url: URL(fileURLWithPath: args["path"] as! String), settings: settings)
            active.isMeteringEnabled = true
            guard active.record(forDuration: 120) else { throw failure("Could not start recording. Check available storage and try again.") }
            recorder = active; result(nil)
        case "finishRecording": recorder?.stop(); recorder = nil; try? AVAudioSession.sharedInstance().setActive(false); result(nil)
        case "amplitude": recorder?.updateMeters(); result(Double(max(0,min(1,((recorder?.averagePower(forChannel: 0) ?? -60)+60)/60))))
        case "play":
            stopAudio(); try AVAudioSession.sharedInstance().setCategory(.playback)
            try AVAudioSession.sharedInstance().setActive(true)
            player = try AVAudioPlayer(contentsOf: URL(fileURLWithPath: args["path"] as! String))
            player?.play(); result(nil)
        case "stopPlayback": player?.stop(); player = nil; if recorder == nil { try? AVAudioSession.sharedInstance().setActive(false) }; result(nil)
        default: result(FlutterMethodNotImplemented)
        }
    }
    private func reminderContent(id: Int) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        if Locale.current.languageCode == "es" {
            content.title = "Un momento para orar"; content.body = "Haz una pausa y da gracias con Cercano a Dios."
        } else {
            content.title = "A time for prayer"; content.body = "Pause and give thanks with Cercano a Dios."
        }
        content.sound = .default; content.categoryIdentifier = "PRAYER"; content.userInfo = ["id":id]
        return content
    }
    @MainActor static func requestPrayer(_ reminder: Int) {
        // The intent can run before Flutter installs its handler on cold launch.
        UserDefaults.standard.set(reminder, forKey: pendingPrayerKey)
        guard let delegate = prayerDelegate, delegate.prayerBridgeReady else { return }
        UserDefaults.standard.removeObject(forKey: pendingPrayerKey)
        delegate.channel?.invokeMethod("openPrayer", arguments: reminder)
    }
    private func stopAudio() {
        recorder?.stop(); recorder = nil; player?.stop(); player = nil
        try? AVAudioSession.sharedInstance().setActive(false)
    }
    @objc private func audioInterrupted() {
        if recorder != nil { channel?.invokeMethod("recordingInterrupted", arguments: nil) }
        stopAudio()
    }
    override func applicationDidEnterBackground(_ application: UIApplication) { stopAudio(); super.applicationDidEnterBackground(application) }
    override func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner,.sound])
    }
    override func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        if response.actionIdentifier == "SNOOZE" {
            let id = response.notification.request.content.userInfo["id"] as? Int ?? 0
            let request = UNNotificationRequest(identifier: "snooze-\(id)", content: reminderContent(id: id), trigger: UNTimeIntervalNotificationTrigger(timeInterval: 600, repeats: false))
            center.add(request) { _ in completionHandler() }
        } else {
            Self.requestPrayer(response.notification.request.content.userInfo["id"] as? Int ?? 0)
            completionHandler()
        }
    }
}

#if canImport(AlarmKit)
@available(iOS 26.0, *)
struct PrayerAlarmMetadata: AlarmMetadata {}

@available(iOS 26.0, *)
struct OpenPrayerIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Stop and pray"
    static var openAppWhenRun: Bool = true
    @Parameter(title: "Alarm identifier") var alarmID: String
    @Parameter(title: "Prayer time") var reminderID: Int
    init() {}
    init(alarmID: String, reminderID: Int) { self.alarmID = alarmID; self.reminderID = reminderID }
    @MainActor func perform() async throws -> some IntentResult {
        // The system may have already stopped it while executing the stop action.
        if let id = UUID(uuidString: alarmID) { try? AlarmManager.shared.stop(id: id) }
        AppDelegate.requestPrayer(reminderID)
        return .result()
    }
}

@available(iOS 26.0, *)
struct SnoozePrayerIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Snooze prayer"
    @Parameter(title: "Alarm identifier") var alarmID: String
    @Parameter(title: "Prayer time") var reminderID: Int
    init() {}
    init(alarmID: String, reminderID: Int) { self.alarmID = alarmID; self.reminderID = reminderID }
    @MainActor func perform() async throws -> some IntentResult {
        if let id = UUID(uuidString: alarmID) { try AlarmManager.shared.stop(id: id) }
        try await NativePrayerAlarms.snooze(reminderID)
        return .result()
    }
}

@available(iOS 26.0, *)
@MainActor enum NativePrayerAlarms {
    static let prefix = "native_prayer_"
    static func key(_ id: Int, snooze: Bool = false) -> String { "\(prefix)\(id)\(snooze ? "_snooze" : "")" }
    static func uuid(_ key: String) -> UUID {
        if let value = UserDefaults.standard.string(forKey: key), let id = UUID(uuidString: value) { return id }
        let id = UUID(); UserDefaults.standard.set(id.uuidString,forKey:key); return id
    }
    static func authorize() async throws {
        guard try await AlarmManager.shared.requestAuthorization() == .authorized else {
            throw NSError(domain:"Cercano",code:1,userInfo:[NSLocalizedDescriptionKey:"Allow alarms in Settings to schedule prayer alarms."])
        }
    }
    static func configuration(id: UUID, reminder: Int, schedule: Alarm.Schedule) -> AlarmManager.AlarmConfiguration<PrayerAlarmMetadata> {
        let alert = AlarmPresentation.Alert(title: "A time for prayer",
            stopButton: AlarmButton(text: "Stop & pray", textColor: .white, systemImageName: "stop.fill"),
            secondaryButton: AlarmButton(text: "Snooze 10 min", textColor: .white, systemImageName: "zzz"),
            secondaryButtonBehavior: .custom)
        let attributes = AlarmAttributes(presentation: AlarmPresentation(alert: alert), metadata: PrayerAlarmMetadata(), tintColor: .green)
        return .alarm(schedule: schedule, attributes: attributes,
            stopIntent: OpenPrayerIntent(alarmID: id.uuidString, reminderID: reminder),
            secondaryIntent: SnoozePrayerIntent(alarmID: id.uuidString, reminderID: reminder))
    }
    static func schedule(_ args: [String:Any]) async throws {
        try await authorize()
        let reminder = args["id"] as! Int
        let days: [Locale.Weekday] = [.monday,.tuesday,.wednesday,.thursday,.friday,.saturday,.sunday]
        let weekdays = (args["weekdays"] as! [Int]).map { days[$0-1] }
        let schedule = Alarm.Schedule.relative(.init(time: .init(hour: args["hour"] as! Int,minute: args["minute"] as! Int), repeats: .weekly(weekdays)))
        let id = uuid(key(reminder))
        _ = try await AlarmManager.shared.schedule(id: id, configuration: configuration(id: id,reminder: reminder,schedule: schedule))
    }
    static func snooze(_ reminder: Int) async throws {
        let id = uuid(key(reminder,snooze:true))
        _ = try await AlarmManager.shared.schedule(id:id,configuration:configuration(id:id,reminder:reminder,schedule:.fixed(Date().addingTimeInterval(600))))
    }
    static func test() async throws {
        try await authorize()
        let id = uuid(key(0))
        _ = try await AlarmManager.shared.schedule(id:id,configuration:configuration(id:id,reminder:0,schedule:.fixed(Date().addingTimeInterval(10))))
    }
    static func cancel(_ reminder: Int) throws {
        let existing = Set(try AlarmManager.shared.alarms.map(\.id))
        for k in [key(reminder),key(reminder,snooze:true)] {
            if let text = UserDefaults.standard.string(forKey:k), let id = UUID(uuidString:text), existing.contains(id) {
                try AlarmManager.shared.cancel(id:id)
            }
            UserDefaults.standard.removeObject(forKey:k)
        }
    }
    static func cancelAll() throws {
        for alarm in try AlarmManager.shared.alarms { try AlarmManager.shared.cancel(id:alarm.id) }
        for k in UserDefaults.standard.dictionaryRepresentation().keys where k.hasPrefix(prefix) { UserDefaults.standard.removeObject(forKey:k) }
    }
    static func stopActive() throws {
        for alarm in try AlarmManager.shared.alarms where alarm.state == .alerting { try AlarmManager.shared.stop(id:alarm.id) }
    }
    static func cancelSnooze(_ reminder: Int) throws {
        let k = key(reminder,snooze:true)
        let existing = Set(try AlarmManager.shared.alarms.map(\.id))
        if let text = UserDefaults.standard.string(forKey:k),let id = UUID(uuidString:text),existing.contains(id) {
            try AlarmManager.shared.cancel(id:id)
        }
        UserDefaults.standard.removeObject(forKey:k)
    }
}
#endif
