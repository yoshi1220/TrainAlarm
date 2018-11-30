//
//  ViewController.swift
//  TrainAlarm
//
//  Created by Yoshiomi on 2018/01/10.
//  Copyright © 2018 Yoshiomi. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation
import AVFoundation
import UserNotifications

class ViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate, UNUserNotificationCenterDelegate {
    
    //緯度経度距離の表示用
    @IBOutlet weak var latitudeLabel: UILabel!
    @IBOutlet weak var longitudeLabel: UILabel!
    @IBOutlet weak var distanceLabel: UILabel!
    
    //地図
    @IBOutlet weak var myMap: MKMapView!
    
    //トラッキングボタン
    @IBOutlet weak var trackingButton: UIBarButtonItem!
    
    //到着判定の距離
    let decisionDistance = 1000
    
    //アラートフラグ
    var canAlarm: Bool = true
    
    //ロケーションマネージャー
    var locationManager = CLLocationManager()
    
    //目的地
    var destination = CLLocationCoordinate2D()
    
    var annotation = MKPointAnnotation()
    
    //便宜上の目的地（初回起動時用)
    let destinationDefault = CLLocationCoordinate2D(latitude: 35.681167, longitude: 139.767052) //東京駅
    
    //到着アラーム用のAudioPlayer
    var player: AVAudioPlayer!
    
    
    //
    //ロード時
    //
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //通知関連の初期化
        initializeNotification()
        
        //アラートサウンド関連の初期化
        initializeSoundPlayer()
        
        //ユーザー情報の読み込み
        readUserDefaultInformation()
        
        //Locationとマップ関連の初期化
        initializeLocationAndMapkit()
        
        //目的地を追加
        makeAnnotation()
        
    }
    
    //ユーザーデフォルト情報を読み込む
    func readUserDefaultInformation() {
        
        let userDefaults = UserDefaults.standard

        //データの存在確認
        if (userDefaults.object(forKey: "Annotaion") != nil) {
            destination.latitude = userDefaults.double(forKey: "latitude")
            destination.longitude = userDefaults.double(forKey: "longitude")
        } else {
            destination = destinationDefault
        }
    }
    
    //到着ラーム用のサウンドプレイヤー関連の初期化
    func initializeSoundPlayer() {
        
        // バックグラウンドでも再生できるカテゴリに設定する
        let session = AVAudioSession.sharedInstance()
        
        do {
            try session.setCategory(AVAudioSessionCategoryPlayback, with: .duckOthers)
        } catch  {
            // エラー処理
            fatalError("カテゴリ設定失敗")
        }
        
        //アラーム用のサウンドを読み込む
        let path = Bundle.main.path(forResource: "alarm.mp3", ofType:nil)!
        let url = URL(fileURLWithPath: path)
        
        do {
            player = try AVAudioPlayer(contentsOf: url)
        } catch {
            print("サウンドファイルが読み込めませんでした。")
        }
    }
    
    //位置情報、マップ関連の初期化
    func initializeLocationAndMapkit() {
        
        // 現在のステータスによって位置情報の利用許可を得る
        authorizeLocationPermission()
        // ロケーションマネージャのデリゲートになる
        locationManager.delegate = self
        // デリゲートを設定
        UNUserNotificationCenter.current().delegate = self
        // myMapのデリゲートになる
        myMap.delegate = self
        // スケールを表示する
        myMap.showsScale = true
        
        // Mapkiをnoneからfollowへ
        myMap.setUserTrackingMode(.follow, animated: true)
        
        // トラッキングボタンを変更する
        trackingButton.image = UIImage(named: "trackingFollow")
    }
    
    func authorizeLocationPermission() {
        //現状の認証を確認する
        switch CLLocationManager.authorizationStatus() {
        case .authorizedAlways:
            //認証は常に許可
            CLLocationManager.locationServicesEnabled()
            break
        case .authorizedWhenInUse:
            //認証は一時許可
            //常に許可をユーザーに問い合わせる
            self.locationManager.requestAlwaysAuthorization()
            break
        case .denied:
            //ユーザーから許可されていない。
            break
        case .notDetermined:
            //一度も認証を問われていない
            //一時許可をユーザーに問い合わせる
            //            self.locationManager.requestWhenInUseAuthorization()
            self.locationManager.requestAlwaysAuthorization()
            break
        case .restricted:
            //ペアレントコントロールなどで制限されている
            print("エラー:restricted")
            break
            
        }
    }
    
    //通知関連の初期化
    func initializeNotification() {
        
        // notification center (singleton)
        let center = UNUserNotificationCenter.current()
        
        // request to notify for user
        center.requestAuthorization(options: [.alert, .badge, .sound]) { (granted, error) in
            if granted {
                print("Allowed")
            } else {
                print("Didn't allowed")
            }
        }
        
    }
    
    //目的地の作成
    //今のところ固定で作成。最終的にはマスタ化する。
    func makeAnnotation() {
        
        
        annotation.coordinate = destination
        annotation.title = "目的地"

        myMap.addAnnotation(annotation)
        
    }
    
    //地図を長押しした際に、目的地を変更する
    @IBAction func mapLongPress(_ sender: UILongPressGestureRecognizer) {
        //長押しの終了でのみ実行する。
        guard sender.state == UIGestureRecognizerState.ended else {
            return
        }
        
        //座標の取得
        let pressPoint = sender.location(in: myMap)
        destination = myMap.convert(pressPoint, toCoordinateFrom: myMap)

        //目的地の再作成
        makeAnnotation()
        
        //目的地の保存
        
    }
    
    // トラッキングモードを切り替える
    @IBAction func tapTrackingButton(_ sender: UIBarButtonItem) {
        switch myMap.userTrackingMode {
        case .none:
            // noneからfollowへ
            myMap.setUserTrackingMode(.follow, animated: true)
            // トラッキングボタンを変更する
            trackingButton.image = UIImage(named: "trackingFollow")
        case .follow:
            // followからfollowWithHeadingへ
            myMap.setUserTrackingMode(.followWithHeading, animated: true)
            // トラッキングボタンを変更する
            trackingButton.image = UIImage(named: "trackingHeading")
        case .followWithHeading:
            // followWithHeadingからnoneへ
            myMap.setUserTrackingMode(.none, animated: true)
            // トラッキングボタンを変更する
            trackingButton.image = UIImage(named: "trackingNone")
        }
    }
    
    // トラッキングが自動解除された
    func mapView(_ mapView: MKMapView, didChange mode: MKUserTrackingMode, animated: Bool) {
        // トラッキングボタンを変更する
        trackingButton.image = UIImage(named: "trackingNone")
    }
    
    // 位置情報利用許可のステータスが変わった
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .authorizedAlways, .authorizedWhenInUse :
            
            //バックグラウンドでも更新が続くようにする
            self.locationManager.allowsBackgroundLocationUpdates = true
            //精度は最強
            self.locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
            // ロケーションの更新を開始する
            self.locationManager.startUpdatingLocation()
            // トラッキングボタンを有効にする
            trackingButton.isEnabled = true
        default:
            // ロケーションの更新を停止する
            locationManager.stopUpdatingLocation()
            // トラッキングモードをnoneにする
            myMap.setUserTrackingMode(.none, animated: true)
            //トラッキングボタンを変更する
            trackingButton.image = UIImage(named: "trackingNone")
            // トラッキングボタンを無効にする
            trackingButton.isEnabled = false
        }
    }
    
    // 位置を移動した
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        // locationsの最後の値を取り出す
        let locationData = locations.last
        
        var latitude: Double = 0
        var longitude: Double = 0
        
        // 緯度
        if let lati = locationData?.coordinate.latitude {
            latitude = round(lati * 1000000) / 1000000
            latitudeLabel.text = String(latitude)
        }
        // 経度
        if let longi = locationData?.coordinate.longitude {
            longitude = round(longi * 1000000) / 1000000
            longitudeLabel.text = String(longitude)
        }
        
        
        
        //目的地までの距離を計算
        let distance = calculateDistance(latitude: latitude, longitude: longitude, destinationLatitude: destination.latitude, destinationLongitude: destination.longitude)

        self.distanceLabel.text = String(distance) + "m"
        //到着判定
        if canAlarm && detectArrival(distance) { //if canAlarm && detectArrival(distance) {

            //アラームは一度鳴らしたら、二度目は鳴らさない。
            canAlarm = false

            //アラートの表示
            alertArrival()
        }
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //現在緯度経度からの目的地までの距離計算
    func calculateDistance(latitude: Double, longitude: Double, destinationLatitude: Double, destinationLongitude: Double) -> Int {
        let presentLocation: CLLocation = CLLocation(latitude: latitude, longitude: longitude)
        let desitination: CLLocation = CLLocation(latitude: destinationLatitude, longitude: destinationLongitude)
        
        return Int(desitination.distance(from: presentLocation))
    }
    
    //到着判定
    func detectArrival(_ distance: Int) -> Bool {
        
        if distance < decisionDistance {
            return true
        }
        
        return false
    }
    
    //到着アラームの表示
    func alertArrival() {
        
        //到着アラーム音を鳴らす。
        playAlertSound()
        
        //到着通知
        notificateArrival()
        
        //アラートを表示する。
        showAlert()
        
    }
    
    //アラートを表示する。
    func showAlert() {
        // アラートを作る
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .alert)
        alert.title = "到着"
        alert.message = "目的地までもう少しです。"
        
        // 確認ボタン
        alert.addAction(
            UIAlertAction(
                title: "OK",
                style: .default,
                handler: {(action) -> Void in
                    self.stopAlertSound()
            }
            )
        )
        
        // アラートを表示する
        self.present(
            alert,
            animated: true,
            completion: {
                // 表示完了後に実行
                print("アラートが表示された")
            }
        )
    }
    
    //到着通知
    func notificateArrival() {
        let seconds = 1
        
        // 通知の発行: タイマーを指定して発行
        // content
        let content = UNMutableNotificationContent()
        content.title = "到着"
        content.subtitle = ""
        content.body = "目的地までもう少しです。"
        content.sound = UNNotificationSound.default()
        
        // カテゴリ（および関連づけられているアクション）を割り当て。
        content.categoryIdentifier = "TIMER_EXPIRED"
        
        // trigger
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: Double(seconds),
                                                        repeats: false)
        
        // request includes content & trigger
        let request = UNNotificationRequest(identifier: "TIMER\(seconds)",
            content: content,
            trigger: trigger)
        
        //通知のカスタムアクション？
        let generalCategory = UNNotificationCategory(identifier: "GENERAL",
                                                     actions: [],
                                                     intentIdentifiers: [],
                                                     options: .customDismissAction)

        // TIMER_EXPIREDカテゴリのカスタムアクションを作成。
        let snoozeAction = UNNotificationAction(identifier: "SNOOZE_ACTION",
                                                title: "Snooze",
                                                options: UNNotificationActionOptions(rawValue: 0))
        let stopAction = UNNotificationAction(identifier: "STOP_ACTION",
                                              title: "Stop",
                                              options: .foreground)
        
        let expiredCategory = UNNotificationCategory(identifier: "TIMER_EXPIRED",
                                                     actions: [snoozeAction, stopAction],
                                                     intentIdentifiers: [],
                                                     options: UNNotificationCategoryOptions(rawValue: 0))
        
        // schedule notification by adding request to notification center
        let center = UNUserNotificationCenter.current()
        center.setNotificationCategories([generalCategory])
        center.setNotificationCategories([expiredCategory])
        
        center.add(request) { (error) in
            if let error = error {
                print(error.localizedDescription)
            }
        }
        
        
    }
    
    //通知がタップされたとき？の制御
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        
        print("userNotificationCenter run")
        
        if response.notification.request.content.categoryIdentifier == "TIMER_EXPIRED" {
            //アラーム音を停止する
            stopAlertSound()
            
            //GPSを停止する
            myMap.setUserTrackingMode(.none, animated: true)
            // トラッキングボタンを変更する
            trackingButton.image = UIImage(named: "trackingNone")
        }
        
        // その他のタイプの通知に関するアクションをハンドル。
    }

    
    //アラーム音を停止する。
    func stopAlertSound() {
        
        //Playerの再生を終了
        player.stop()
        
        //Audioのセッションを非アクティブにする
        let session = AVAudioSession.sharedInstance()
        try! session.setActive(false)
    }
    
    //到着時にアラームを鳴らして利用者に知らせる。
    func playAlertSound() {
        
        //        //アラートサウンド関連の初期化
        //        initializeSoundPlayer()
        
        //バイブレーション
        AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
        
        //Audioのセッションをアクティブ化
        let session = AVAudioSession.sharedInstance()
        
        do {
            try session.setActive(true)
        } catch {
            // audio session有効化失敗時の処理
            // (ここではエラーとして停止している）
            fatalError("session有効化失敗")
        }
        //アラームの再生
        player.play()
    }
}

