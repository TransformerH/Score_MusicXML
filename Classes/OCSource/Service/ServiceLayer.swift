//
//  Test.swift
//  CIProgressHUD
//
//  Created by tanhui on 2017/11/13.
//

import Foundation
import Moya
import RxSwift
import SwiftyJSON
import CIUtilS
import CIRouter

public class ConstValue: NSObject{
    static let defaultConst = ConstValue()
    public var baseUrl: String?;
    
    @objc public class func setUrl(_ url: String) {
        defaultConst.baseUrl = url
    }
    @objc class func getUrl() -> String {
        return defaultConst.baseUrl ?? ""
    }
}

enum MusicApiManager {
    case getScore(String,String,String,String,String,String,String) //  获取分数
}

extension MusicApiManager: TargetType {
    var headers: [String : String]? {
        return nil
    }
    
    
    var baseURL: URL {
        let scoreurl = ConstValue.getUrl()
        return URL.init(string: scoreurl)!
    }
    var path: String {
        switch self {
        case .getScore:
            return "Play/getScore"
        }
    }
    var method: Moya.Method {
        return .post
    }
    var parameters: [String: Any]? {
        switch self {
        case let .getScore( scoreID, channelID, accountID, token, data,type, typeID):
            return ["id": scoreID,
                    "channelID": channelID,
                    "accountID": accountID,
                    "token": token,
                    "data": data,
                    "type": type,
                    "typeID":typeID,
            ]
        default:
            return nil
        }
    }
    var parameterEncoding: ParameterEncoding {
        return URLEncoding.default
    }
    var sampleData: Data {
        return "".data(using: String.Encoding.utf8)!
    }
    var task: Task {
        switch self {
        case let .getScore( scoreID, channelID, accountID, token, data,type, typeID):
            let params = ["id": scoreID,
                          "channelID": channelID,
                          "accountID": accountID,
                          "token": token,
                          "data": data,
                          "type": type,
                          "typeID":typeID,
            ]
            return .requestParameters(parameters: params, encoding: URLEncoding.default)
        }
        
    }
}

public class MusicService :NSObject{
    let mDisposeBag = DisposeBag()
    static let defaultMusicService = MusicService()
    @objc public class func shareService () -> MusicService {
        return defaultMusicService
    }
    @objc public func fetchScore(scoreID: Int, accountID: String, channelID: Int, token: String, data: String,typeID: Int, type: String, success: @escaping (Int)-> Void, error: @escaping ()->Void) {
        
        let provider = MoyaProvider<MusicApiManager>()
        
        provider.rx.request(.getScore(String(scoreID), String(channelID), accountID , token, data, type, String(typeID)))
            .filterSuccessfulStatusCodes()
            .mapJSON()
            .subscribe(onSuccess: { (jsonObject) in
                let json = JSON(jsonObject)
                if let score = json["data","score"].int {
                    success(score)
                } else {
                    error()
                }

            }) { (_) in
                error()
        }.disposed(by: mDisposeBag)
    }
    
    
}

public class UtilService: NSObject {
    let currentVersion = "1.0" // 10.36 developing
    @objc public func showTips() -> Bool {
        let userDefault = CIUserDefault()
        let show = userDefault.checkMusicXMLSplashfor(version: currentVersion)
        let synchronize = userDefault.updateMusicXMLSplashFor(version: currentVersion)
        return !show && synchronize
    }
    @objc public func blueModuleName() -> String {
        return bluetoothModule
    }
}
