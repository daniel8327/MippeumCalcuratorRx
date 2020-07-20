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

    static let url = "https://firebasestorage.googleapis.com/v0/b/testdaniel111-58bd3.appspot.com/o/a.json?alt=media&token=df8bfeab-41c2-4428-b4c0-cc1f5536a198"
    
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
    
    static func fetchAllMenusRx() -> Observable<Data> {
        return Observable.create { emitter in
            fetchAllMenus() { result in
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
}
