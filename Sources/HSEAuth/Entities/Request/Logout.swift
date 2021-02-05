import Foundation

public struct Logout: HSERequest {
  public typealias ResponseResult = LogoutResponse
  var host: String? = "logout"
  
  var method: RequestMethod = .post
  public var path: String = ""
  let body: Data?
  
  public init() {
    body = nil
  }
}
