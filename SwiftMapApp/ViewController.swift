//
//  ViewController.swift
//  SwiftMapApp
//
//  Created by Natsumo Ikeda on 2016/08/10.
//  Copyright © 2016年 NIFTY Corporation. All rights reserved.
//

import UIKit
import NCMB
import GoogleMaps

class ViewController: UIViewController, CLLocationManagerDelegate {
    // Google Map
    @IBOutlet weak var mapView: GMSMapView!
    // TextField
    @IBOutlet weak var latTextField: UITextField!
    @IBOutlet weak var lonTextField: UITextField!
    // Label
    @IBOutlet weak var label: UILabel!
    // 現在地
    var myLocation: CLLocation!
    var locationManager: CLLocationManager!
    // マーカー
    var marker: GMSMarker!
    // mBaaSデータストア「Shop」クラスデータ格納用
    var shopData: Array<NCMBObject>!
    
    // 新宿駅の位置情報
    let SHINJUKU_LAT = 35.690549
    let SHINJUKU_LON = 139.699550
    // 西新宿駅の位置情報
    let WEST_SHINJUKU_LAT = 35.6945080
    let WEST_SHINJUKU_LON = 139.692692
    // ニフティの位置情報
    let NIFTY_LAT = 35.696144
    let NIFTY_LON = 139.689485
    // ズームレベル
    let ZOOM: Float = 14.5
    // 検索範囲
    let SEAECH_RANGE = ["全件検索", "現在地から半径5km以内を検索", "現在地から半径1km以内を検索", "新宿駅と西新宿駅の間を検索"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 位置情報取得開始
        if CLLocationManager.locationServicesEnabled() {
            locationManager = CLLocationManager()
            locationManager.delegate = self
            locationManager.startUpdatingLocation()
        }
        
        // 起動時は新宿駅に設定
        showMap(SHINJUKU_LAT, longitude: SHINJUKU_LON)
        addMarker(SHINJUKU_LAT, longitude: SHINJUKU_LON, title: "新宿駅", snippet: "Shinjuku Station", color: UIColor.greenColor())
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        
        // 位置情報取得の停止
        if CLLocationManager.locationServicesEnabled() {
            locationManager.stopUpdatingLocation()
        }
    }
    
    // 位置情報許可状況確認メソッド
    func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        switch status {
        case .NotDetermined:
            // 初回のみ許可要求
            locationManager.requestWhenInUseAuthorization()
        case .Restricted, .Denied:
            // 位置情報許可を依頼するアラートの表示
            alertLocationServiceDisabled()
        case .AuthorizedAlways, .AuthorizedWhenInUse:
            break
        }
    }
    
    // 位置情報許可依頼アラート
    func alertLocationServiceDisabled() {
        let alert = UIAlertController(title: "位置情報が許可されていません", message: "位置情報サービスを有効にしてください", preferredStyle: .Alert)
        alert.addAction(UIAlertAction(title: "設定", style: .Default, handler: { (action: UIAlertAction) -> Void in
            let url = NSURL(string: UIApplicationOpenSettingsURLString)!
            UIApplication.sharedApplication().openURL(url)
        }))
        alert.addAction(UIAlertAction(title: "キャンセル", style: .Cancel, handler: { (action: UIAlertAction) -> Void in
        }))
        presentViewController(alert, animated: true, completion: nil)
    }
    
    // 位置情報が更新されるたびに呼ばれるメソッド
    func locationManager(manager: CLLocationManager, didUpdateToLocation newLocation: CLLocation, fromLocation oldLocation: CLLocation) {
        // 値をローカルに保存
        myLocation = newLocation
        // TextFieldに表示
        self.latTextField.text = "".stringByAppendingFormat("%.6f", newLocation.coordinate.latitude)
        self.lonTextField.text = "".stringByAppendingFormat("%.6f", newLocation.coordinate.longitude)
        self.label.text = "右上の「保存」をタップしてmBaaSに保存しよう！"
    }
    
    // 「保存」ボタン押下時の処理
    @IBAction func saveLocation(sender: UIButton) {
        // チェック
        if myLocation == nil {
            print("位置情報が取得できていません")
            label.text = "位置情報が取得できていません"
            return
        } else {
            print("位置情報が取得できました")
            label.text = "位置情報が取得できました"
            
            // アラートを表示
            let alert = UIAlertController(title: "現在地を保存します", message: "情報を入力してください", preferredStyle: .Alert)
            // UIAlertControllerにtextFieldを2つ追加
            alert.addTextFieldWithConfigurationHandler { (textField: UITextField!) -> Void in
                textField.placeholder = "タイトル"
            }
            alert.addTextFieldWithConfigurationHandler { (textField: UITextField!) -> Void in
                textField.placeholder = "コメント"
            }
            // アラートの保存押下時の処理
            alert.addAction(UIAlertAction(title: "保存", style: .Default) { (action: UIAlertAction!) -> Void in
                // 入力値の取得
                let title = alert.textFields![0].text
                let snippet = alert.textFields![1].text
                let lat = "".stringByAppendingFormat("%.6f", self.myLocation.coordinate.latitude)
                let lon = "".stringByAppendingFormat("%.6f", self.myLocation.coordinate.longitude)
                
                /** 【mBaaS：データストア】位置情報の保存 **/
                 // NCMBGeoPointの生成
                let geoPoint = NCMBGeoPoint(latitude: atof(lat), longitude: atof(lon))
                // NCMBObjectを生成
                let object = NCMBObject(className: "GeoPoint")
                // 値を設定
                object.setObject(geoPoint, forKey: "geolocation")
                object.setObject(title, forKey: "title")
                object.setObject(snippet, forKey: "snippet")
                // 保存の実施
                object.saveInBackgroundWithBlock { (error: NSError!) -> Void in
                    if error != nil {
                        // 位置情報保存失敗時の処理
                        print("位置情報の保存に失敗しました：\(error.code)")
                        self.label.text = "位置情報の保存に失敗しました：\(error.code)"
                    } else {
                        // 位置情報保存成功時の処理
                        print("位置情報の保存に成功しました：[\(geoPoint.latitude), \(geoPoint.longitude)]")
                        self.label.text = "位置情報の保存に成功しました：[\(geoPoint.latitude), \(geoPoint.longitude)]"
                        // マーカーを設置
                        self.addMarker(geoPoint.latitude, longitude: geoPoint.longitude, title: object.objectForKey("title") as! String, snippet: object.objectForKey("snippet") as! String, color: UIColor.blueColor())
                    }
                }
                
            })
            // アラートのキャンセル押下時の処理
            alert.addAction(UIAlertAction(title: "キャンセル", style: .Default) { (action: UIAlertAction!) -> Void in
                self.label.text = "保存がキャンセルされました"
                print("保存がキャンセルされました")
            })
            presentViewController(alert, animated: true, completion: nil)
        }
    }
    
    // 「保存した場所を見る」ボタン押下時の処理
    @IBAction func getLocationData(sender: UIBarButtonItem) {
        // Action Sheet
        let actionSheet = UIAlertController(title: "保存した場所を地図に表示します", message: "検索範囲を選択してください", preferredStyle: .ActionSheet)
        // iPadの場合
        if UIDevice.currentDevice().userInterfaceIdiom == .Pad {
            print("iPad使用")
            actionSheet.popoverPresentationController!.sourceView = self.view;
            actionSheet.popoverPresentationController!.sourceRect = CGRectMake(self.view.bounds.size.width*0.5, self.view.bounds.size.height*0.9, 1.0, 1.0);
            actionSheet.popoverPresentationController!.permittedArrowDirections = UIPopoverArrowDirection.Down
        }
        
        // キャンセル
        let cancel = UIAlertAction(title: "キャンセル", style: .Cancel) { (action: UIAlertAction!) -> Void in
        }
        // 全件検索
        let allSearch = UIAlertAction(title: SEAECH_RANGE[0], style: .Default) { (action: UIAlertAction!) -> Void in
            self.getLocaion(action.title!)
        }
        // 円形検索(半径5km以内)
        let round5km = UIAlertAction(title: SEAECH_RANGE[1], style: .Default) { (action: UIAlertAction) -> Void in
            self.getLocaion(action.title!)
        }
        // 円形検索(半径1km以内)
        let round1km = UIAlertAction(title: SEAECH_RANGE[2], style: .Default) { (action: UIAlertAction) -> Void in
            self.getLocaion(action.title!)
        }
        // 矩形検索
        let rectangle = UIAlertAction(title: SEAECH_RANGE[3], style: .Default) { (action: UIAlertAction) -> Void in
            self.getLocaion(action.title!)
        }
        
        // 設定
        actionSheet.addAction(cancel)
        actionSheet.addAction(allSearch)
        actionSheet.addAction(round5km)
        actionSheet.addAction(round1km)
        actionSheet.addAction(rectangle)
        // アラートを表示する
        presentViewController(actionSheet, animated: true, completion: nil)
        
    }
    
    /** 【mBaaS：データストア(位置情報)】保存データの取得 **/
    func getLocaion(title: String) {
        // チェック
        if myLocation == nil {
            return
        }
        
        // 現在地
        let geoPoint = NCMBGeoPoint(latitude: myLocation.coordinate.latitude, longitude: myLocation.coordinate.longitude)
        // 新宿駅
        let shinjukuGeoPoint = NCMBGeoPoint(latitude: SHINJUKU_LAT, longitude: SHINJUKU_LON)
        // 西新宿駅
        let westShinjukuGeoPoint = NCMBGeoPoint(latitude: WEST_SHINJUKU_LAT, longitude: WEST_SHINJUKU_LON)
        // それぞれのクラスの検索クエリを作成
        let queryGeoPoint = NCMBQuery(className: "GeoPoint")
        let queryShop = NCMBQuery(className: "Shop")
        // 検索条件を設定
        switch title {
        case SEAECH_RANGE[0]:
            print(SEAECH_RANGE[0])
            break
        case SEAECH_RANGE[1]:
            print(SEAECH_RANGE[1])
            // 半径5km以内(円形検索)
            queryGeoPoint.whereKey("geolocation", nearGeoPoint: geoPoint, withinKilometers: 5.0)
            queryShop.whereKey("geolocation", nearGeoPoint: geoPoint, withinKilometers: 5.0)
        case SEAECH_RANGE[2]:
            print(SEAECH_RANGE[2])
            // 半径1km以内(円形検索)
            queryGeoPoint.whereKey("geolocation", nearGeoPoint: geoPoint, withinKilometers: 1.0)
            queryShop.whereKey("geolocation", nearGeoPoint: geoPoint, withinKilometers: 1.0)
        case SEAECH_RANGE[3]:
            print(SEAECH_RANGE[3])
            // 新宿駅と西新宿駅の間(矩形検索)
            queryGeoPoint.whereKey("geolocation", withinGeoBoxFromSouthwest: shinjukuGeoPoint, toNortheast: westShinjukuGeoPoint)
            queryShop.whereKey("geolocation", withinGeoBoxFromSouthwest: shinjukuGeoPoint, toNortheast: westShinjukuGeoPoint)
        default:
            print("\(SEAECH_RANGE[0])(エラー)")
            break
        }
        // データストアを検索
        queryGeoPoint.findObjectsInBackgroundWithBlock({ (objects: Array!, error: NSError!) -> Void in
            if error != nil {
                // 検索失敗時の処理
                print("GeoPointクラスの検索に失敗しました:\(error.code)")
                self.label.text = "GeoPointクラスの検索に失敗しました:\(error.code)"
            } else {
                // 検索成功時の処理
                print("GeoPointクラスの検索に成功しました")
                self.label.text = "GeoPointクラスの検索に成功しました"
                for object in objects {
                    let point = object.objectForKey("geolocation") as! NCMBGeoPoint
                    self.addMarker(point.latitude, longitude: point.longitude, title: object.objectForKey("title") as! String, snippet: object.objectForKey("snippet") as! String, color: UIColor.blueColor())
                }
            }
        })
        queryShop.findObjectsInBackgroundWithBlock({ (objects: Array!, error: NSError!) -> Void in
            if error != nil {
                // 検索失敗時の処理
                print("Shopクラスの検索に失敗しました:\(error.code)")
                self.label.text = "Shopクラスの検索に失敗しました:\(error.code)"
            } else {
                // 検索成功時の処理
                print("Shopクラスの検索に成功しました")
                self.label.text = "Shopクラスの検索に成功しました"
                for object in objects {
                    self.addImageMarker(object.objectForKey("geolocation")!.latitude, longitude: object.objectForKey("geolocation")!.longitude, title: object.objectForKey("shopName") as! String, snippet: object.objectForKey("category") as! String, imageName: object.objectForKey("image") as! String)
                }
            }
        })
    }
    
    // 「お店（スプーンとフォーク）」ボタン押下時の処理
    @IBAction func showShops(sender: UIBarButtonItem) {
        // Shopデータの取得
        getShopData()
        // チェック
        if shopData == nil {
            print("Shop情報の取得に失敗しました")
            label.text = "Shop情報の取得に失敗しました"
            
            return
        } else {
            print("Shop情報の取得に成功しました")
            label.text = "Shop情報の取得に成功しました"
            
            // マーカーを設定
            for shop in shopData {
                addImageMarker(shop.objectForKey("geolocation").latitude, longitude: shop.objectForKey("geolocation").longitude, title: shop.objectForKey("shopName") as! String, snippet: shop.objectForKey("category") as! String, imageName: shop.objectForKey("image") as! String)
            }
        }
    }
    
    /** 【mBaaS：データストア】「Shop」クラスのデータを取得 **/
    func getShopData() {
        // 「Shop」クラスの検索クエリを作成
        let query = NCMBQuery(className: "Shop")
        // データストアを検索
        query.findObjectsInBackgroundWithBlock({ (objects: Array!, error: NSError!) -> Void in
            if error != nil {
                // 検索失敗時の処理
                print("Shopクラス検索に失敗しました:\(error.code)")
            } else {
                // 検索成功時の処理
                print("Shopクラス検索に成功しました")
                // AppDelegateに「Shop」クラスの情報を保持
                self.shopData = objects as! Array
            }
        })
    }
    
    // 「nifty」ボタン押下時の処理
    @IBAction func showNifty(sender: UIBarButtonItem) {
        // マーカーを設定
        addImageMarker(NIFTY_LAT, longitude: NIFTY_LON, title: "ニフティ株式会社", snippet: "NIFTY Corporation", imageName: "mBaaS.png")
    }
    
    // 地図を表示
    func showMap (latitude: CLLocationDegrees, longitude: CLLocationDegrees) {
        // cameraの作成と設定
        let camera = GMSCameraPosition.cameraWithLatitude(latitude,longitude: longitude, zoom: ZOOM)
        mapView.camera = camera
        // 現在地の有効化
        mapView.myLocationEnabled = true
        // 現在地を示す青い点を表示
        mapView.settings.myLocationButton = true
    }
    
    // マーカー作成
    func addMarker (latitude: CLLocationDegrees, longitude: CLLocationDegrees, title: String, snippet: String, color: UIColor) {
        
        marker = GMSMarker()
        // 位置情報
        marker.position = CLLocationCoordinate2DMake(latitude, longitude)
        // タイトル
        marker.title = title
        // コメント
        marker.snippet = snippet
        // アイコン
        marker.icon = GMSMarker.markerImageWithColor(color)
        // マーカー表示時のアニメーションを設定
        marker.appearAnimation = kGMSMarkerAnimationPop
        // マーカーを表示するマップの設定
        marker.map = mapView
    }

    // マーカー作成（画像アイコン）
    func addImageMarker(latitude: CLLocationDegrees, longitude: CLLocationDegrees, title: String, snippet: String, imageName: String) {
        let marker = GMSMarker()
        // 位置情報
        marker.position = CLLocationCoordinate2DMake(latitude, longitude)
        // shopName
        marker.title = title
        // category
        marker.snippet = snippet
        
        /** 【mBaaS：ファイルストア】アイコン画像データを取得 **/
        // ファイル名を設定
        let imageFile = NCMBFile.fileWithName(imageName, data: nil)
        // ファイルを検索
        imageFile.getDataInBackgroundWithBlock{ (data: NSData!, error: NSError!) -> Void in
            if error != nil {
                // ファイル取得失敗時の処理
                print("\(snippet)icon画像の取得に失敗しました:\(error.code)")
            } else {
                // ファイル取得成功時の処理
                print("\(snippet)icon画像の取得に成功しました")
                // 画像アイコン
                marker.icon = UIImage.init(data: data)
            }
        }
        
        // マーカー表示時のアニメーションを設定
        marker.appearAnimation = kGMSMarkerAnimationPop
        // マーカーを表示するマップの設定
        marker.map = mapView
    }
    
    // 「ゴミ箱」ボタン押下時の処理
    @IBAction func clearMarker(sender: UIBarButtonItem) {
        // マーカーを全てクリアする
        mapView.clear()
    }
}

