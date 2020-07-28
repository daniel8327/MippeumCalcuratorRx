//
//  MenuAPIStore.swift
//  MippeumCalcuratorRx
//
//  Created by 장태현 on 2020/07/28.
//  Copyright © 2020 장태현. All rights reserved.
//

import Foundation

import RxSwift

protocol MenuAPIFetchable {
    func fetch() -> Observable<[Menu]>
}

class MenuAPIStore: MenuAPIFetchable {
    
    func fetch() -> Observable<[Menu]> {
        
        struct Response: Decodable {
            let menus: [Menu]
        }

        return APIService.fetchAllMenusRx()
            .map { data in
                guard let response = try? JSONDecoder().decode(Response.self, from: data) else {
                    throw NSError(domain: "Decoding error", code: -1, userInfo: nil)
                }
                
                return response.menus
            }
    }
}
