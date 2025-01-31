class WelcomeStorage {
  private enum UserDefaultsKeys {
    static let needTermsKey = "TermsOfUseController_needTerms"
    static let ppLinkKey = "TermsOfUseController_ppLink"
    static let tosLinkKey = "TermsOfUseController_tosLink"
    static let acceptTimeKey = "TermsOfUseController_acceptTime"
  }

  static var privacyPolicyLink: String {
    get {
      return UserDefaults.standard.string(forKey: UserDefaultsKeys.ppLinkKey) ?? ""
    }
    set {
      UserDefaults.standard.set(newValue, forKey: UserDefaultsKeys.ppLinkKey)
    }
  }

  static var termsOfUseLink: String {
    get {
      return UserDefaults.standard.string(forKey: UserDefaultsKeys.tosLinkKey) ?? ""
    }
    set {
      UserDefaults.standard.set(newValue, forKey: UserDefaultsKeys.tosLinkKey)
    }
  }

  static var acceptTime: Date {
    get {
      return Date(timeIntervalSince1970: UserDefaults.standard.double(forKey: UserDefaultsKeys.acceptTimeKey))
    }
    set {
      UserDefaults.standard.set(newValue.timeIntervalSince1970, forKey: UserDefaultsKeys.acceptTimeKey)
    }
  }
}
