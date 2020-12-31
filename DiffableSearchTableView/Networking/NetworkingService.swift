//
//  NetworkingService.swift
//  DiffableSearchTableView
//
//  Created by Nir Leshem on 30/12/2020.
//

import Foundation
import Moya

enum NetworkingService {
    enum UsersProvider: TargetType {

        case getUsers

        var baseURL: URL {
            return URL(string: "https://jsonplaceholder.typicode.com")!
        }

        var path: String {
            switch self {
            case .getUsers:
                return "/users"
            }
        }

        var method: Moya.Method {
            return .get
        }

        var sampleData: Data {
            return Data()
        }

        var task: Task {
            return .requestPlain
        }

        var headers: [String : String]? {
            return nil
        }
    }
}
