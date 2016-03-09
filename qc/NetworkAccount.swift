struct NetworkAccount {
  let networkName: String
  let password: String
}

extension NetworkAccount: CreateableSecureStorable {
  var data: [String: AnyObject] {
    return ["network:": self.networkName, "password": self.password]
  }
}

extension NetworkAccount: GenericPasswordSecureStorable {
  var service: String { return "qc" }
  var account: String { return self.networkName }
}

extension NetworkAccount: ReadableSecureStorable {}
extension NetworkAccount: DeleteableSecureStorable {}
