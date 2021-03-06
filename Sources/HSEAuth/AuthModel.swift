import AuthenticationServices
import SafariServices

public class AuthModel {
  
  private let clientId: String
  
  public var session: NSObject? = nil
  public var authManager: AuthManager?
  private var config: OpenIdConfigResponse?
  private let networkClient: NetworkClient
  private let redirectScheme: String
  private let redirectUrl: String
  
  public init(
    with clientId: String,
    redirectScheme: String,
    host: String,
    reditectPath: String
  ) {
    self.clientId = clientId
    networkClient = NetworkClient(host: host)
    self.redirectScheme = redirectScheme
    redirectUrl = redirectScheme + "://" + host + reditectPath
  }
  
  func auth(
    url: URL,
    callbackScheme: String
  ) -> Result<URL, Error> {
    var result: Result<URL, Error>!
    let semaphore = DispatchSemaphore(value: 0)
    
    if #available(iOS 12, *) {
      let session = ASWebAuthenticationSession(
        url: url,
        callbackURLScheme: callbackScheme
      )
      {
        if let resultUrl = $0 {
          result = .success(resultUrl)
        }
        if let error = $1 {
          result = .failure(error)
        }
        semaphore.signal()
      }
      if #available(iOS 13.0, *) {
        session.presentationContextProvider = authManager
      }
      session.start()
      self.session = session
    } else {
      let session = SFAuthenticationSession(
        url: url,
        callbackURLScheme: callbackScheme
      )
      {
        if let resultUrl = $0 {
          result = .success(resultUrl)
        }
        if let error = $1 {
          result = .failure(error)
        }
        semaphore.signal()
      }
      session.start()
      self.session = session
    }
    _ = semaphore.wait(wallTimeout: .distantFuture)
    return result
  }
  
  func getAccessToken(for code: String) -> Result<AccessTokenResponse, Error> {
    let request = AccessTokenRequest(code: code, clientId: clientId, redirectUrl: redirectUrl)
    return networkClient.search(request: request)
  }
  
  func getCode() -> Result<String, Error> {
    guard let authUrl = URL(string: config?.authorizationEndpoint ?? "") else { preconditionFailure("something wrong") }
    
    let urlComponents = URLComponents(url: authUrl, resolvingAgainstBaseURL: false)?
      .add(key: "response_type", value: "code")
      .add(key: "client_id", value: clientId)
      .add(key: "redirect_uri", value: redirectUrl)
      .add(key: "scope", value: ["profile", "openid"].joined(separator: " "))
    
    guard let url = urlComponents?.url else { preconditionFailure("something wrong") }
    
    return auth(
      url: url,
      callbackScheme: redirectScheme
    )
    .flatMap {
      guard
        let components = URLComponents(
          url: $0,
          resolvingAgainstBaseURL: false
        ),
        let code = (
          components.queryItems?
            .first(where: { $0.name == "code" })
            .flatMap { $0.value }
        )
      else { preconditionFailure("something wrong") }
      return .success(code)
    }
  }
  
  func getOpenIdConfig() -> Result<OpenIdConfigResponse, Error> {
    let request = OpenIdConfigRequest()
    return networkClient.search(request: request)
      .flatMap { [weak self] result -> Result<OpenIdConfigResponse, Error> in
        self?.config = result
        return .success(result)
      }
  }
  
  public func logout(callbackScheme: String) -> Result<URL, Error> {
    var urlComponents = URLComponents()
    urlComponents.scheme = "https"
    let request = Logout()
    urlComponents.host = request.host
    urlComponents.path = request.path
    
    guard let url = urlComponents.url else { preconditionFailure("error in url") }
    var result: Result<URL, Error>!
    let semaphore = DispatchSemaphore(value: 0)
    
    if #available(iOS 12, *) {
      let session = ASWebAuthenticationSession(
        url: url,
        callbackURLScheme: callbackScheme
      )
      {
        if let resultUrl = $0 {
          result = .success(resultUrl)
        }
        if let error = $1 {
          result = .failure(error)
        }
        semaphore.signal()
      }
      if #available(iOS 13.0, *) {
        session.presentationContextProvider = authManager
      }
      session.start()
      self.session = session
    } else {
      let session = SFAuthenticationSession(
        url: url,
        callbackURLScheme: callbackScheme
      )
      {
        if let resultUrl = $0 {
          result = .success(resultUrl)
        }
        if let error = $1 {
          result = .failure(error)
        }
        semaphore.signal()
      }
      session.start()
      self.session = session
    }
    _ = semaphore.wait(wallTimeout: .distantFuture)
    return result
  }
}

extension AuthModel: AuthManagerProtocol {
  public func auth() -> Result<AccessTokenResponse, Error> {
    return getOpenIdConfig()
      .flatMap { [weak self] in
        guard let self = self else { preconditionFailure() }
        self.config = $0
        return self.getCode()
      }
      .flatMap { getAccessToken(for: $0) }
  }
  
  public func refreshAccessToken(with refreshToken: String) -> Result<AccessTokenResponse, Error> {
    let request = RefreshAccessTokenRequest(clientId: clientId, refreshToken: refreshToken)
    return networkClient.search(request: request)
  }
}
