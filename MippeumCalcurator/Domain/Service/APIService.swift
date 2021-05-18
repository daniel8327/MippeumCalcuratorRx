//
//  APIService.swift
//  MippeumCalcurator3
//
//  Created by 장태현 on 2020/07/20.
//  Copyright © 2020 장태현. All rights reserved.
//

import Foundation
import RxSwift

class APIService {

    // 짧은거
    //static let url = "https://firebasestorage.googleapis.com/v0/b/testdaniel111-58bd3.appspot.com/o/a.json?alt=media&token=df8bfeab-41c2-4428-b4c0-cc1f5536a198"
    
    // 긴거 
    //static let url = "https://firebasestorage.googleapis.com/v0/b/testdaniel111-58bd3.appspot.com/o/b.json?alt=media&token=9e69849d-baa1-45f7-a491-2f19226c8b4e"
    
    static let url = "https://00f74ba44b729f69ecb21cdf422fcf6aaf6b97b712-apidata.googleusercontent.com/download/storage/v1/b/staging.mippeumcalcuratorrx.appspot.com/o/mippeumcalcuratorrx-default-rtdb-export.json?jk=AFshE3Us4NtnCiSlLYeqSm4MLUniU2enxZASCGhIXoXwtINVgGhPvvH13WxWVo9PGvY3iG3Ua96HXE-jp8CpKg2_Qi8h9_T5TDlm8U4omw058f6tzQen63MSsnDbltyTo1rvJVp2lL-PN8e5ORWvrbhV_oD04y63IoKcBxaWa8J4gX1dudqbBwGXjtuNwtXEwdIXalp18dFpW6zhosO1Ai0X8O0ycqmgZHoPe82sTVLRKQJ1l84xNP7VldYR0WUoL00Q2tQ99W7XAQ6sFr2_4NTt-cF_EFwhoPJa1bCevn7NoacNh6hcw4xFSIetbUUPz4QWUay9YE0nnxpGkioehD3ug1FaPc9hStgYivfFfpCkTJ-Sm4dTjrKBxqtYLuv8rPMTEK21A3JfreFFGcDQ1jQHOHjCdesw9Cvu3P7TsJctg1RP0oPBYT06Mroy1HqlgeyQ2CS_X4cyIEX44U1vRVtc7HLHFCCKm4-Ruu99lqWembbPau7v-IeEUuYQXOEeHB-fxlAd1eurYemoDXh06PhmrD6qzfJ04ZxzI5h8IbV_M4J3pghlYbFK3JIluMzn7zaj8v-nGtuw6_gQoFfPBWVTTdBO_1TIpElXs39iR7U3o5JwbY0pFhyTXt8e9OTMBwD3PGMxr2mm4_ccvvo-XMqZDvW8X7uju96Ifv5frJYmjIReXBB2fTpGF2hceqvel6GSOE7LcemBCXKMLAvVnHPQSRbhJ2H2u0mlO-qP9mMDZXr6AOG6LWNVWNimaJ0R0XExdtoViMl_bONcYmF742Qspxc7jmHWKGE8_9HrUXfi3Zx_OxKFtFDW-fpMaV1_GvlyFcVTLSqhoF8Qqnu6L4K-582h8FOQPdY4UFMSC36wUiFXq5poZMlmPYRp_s58SOoPlCPH3CRzWvtFklkzTWua4TkGqXoS0e6MqmR-l7oJO1OYtsRHrCzxkpFT4NCqN8H-hFd-FfBGFIkm33Usjpgb5qVgZUNb9k9UFNjU8RLWs848zY0s-aGymAQ6ENcRsTW5VVpJFRCaiKSBQLI&isca=1"
    
    static func fetchAllMenusRx() -> Observable<Data> {
        return Observable.create { emitter in
            fetchAllMenus { result in
                switch result {
                case let .success(data):
                    emitter.onNext(data)
                    emitter.onCompleted()
                case let .failure(error):
                    emitter.onError(error)
                }
            }
            return Disposables.create()
        }
    }
    
    static func fetchAllMenus(onComplete: @escaping (Result<Data, Error>) -> Void) {
        URLSession.shared.dataTask(with: URL(string: url)!) { data, res, err in
            if let err = err {
                onComplete(.failure(err))
                return
            }
            guard let data = data else {
                let httpResponse = res as! HTTPURLResponse
                onComplete(.failure(NSError(domain: "no data",
                                            code: httpResponse.statusCode,
                                            userInfo: nil)))
                return
            }
            onComplete(.success(data))
        }.resume()
    }
}
