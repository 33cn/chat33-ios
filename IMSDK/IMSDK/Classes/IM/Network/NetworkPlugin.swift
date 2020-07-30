//
//  NetworkPlugin.swift
//  Chat33
//
//  Created by 吴文拼 on 2018/9/20.
//  Copyright © 2018年 吴文拼. All rights reserved.
//

import Foundation
import Moya
import Result
import MBProgressHUD
class NetworkPlugin: PluginType {

    func willSend(_ request: RequestType, target: TargetType) {
        guard let target = target as? ServerAPI else {return}
        #if DEBUG
        var requestString = "--RequestUrl: \(target.baseURL.absoluteString)\(target.path)\n--Method: \(target.method.rawValue)"
        if let params = target.parameters {
            requestString += "\n--Params: \(params)"
        }
        if let header = request.request?.allHTTPHeaderFields {
            requestString += "\n--RequestHeader:\(header)"
        }
        print(requestString)
        #endif
    }
    
    func didReceive(_ result: Result<Response, MoyaError>, target: TargetType) {
        switch result {
        case .success(let response):
            guard let target = target as? ServerAPI else {return}
            #if DEBUG
            var requestString = "--RequestUrl: \(target.baseURL.absoluteString)\(target.path)\n--Method: \(target.method.rawValue)"
            if let params = target.parameters {
                requestString += "\n--Params: \(params)"
            }
            requestString += "\n--ResponseData:\(response.responseJSON ?? "空")"
            print(requestString)
            #endif
        case .failure(let error):
            #if DEBUG
            print("TireDetail response case error:")
            print(error)
            #endif
        }
    }
    
}
