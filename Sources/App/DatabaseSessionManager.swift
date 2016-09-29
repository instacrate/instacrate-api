//
//  DatabaseSessionManager.swift
//  subber-api
//
//  Created by Hakon Hanesand on 9/28/16.
//
//

import Turnstile
import Random
import Cache

public final class DatabaseSessionManager: SessionManager {
    private let cache: CacheProtocol
    private let realm: Realm
    
    public init(cache: CacheProtocol, realm: Realm) {
        self.cache = cache
        self.realm = realm
    }
    
    public func restoreAccount(fromSessionID identifier: String) throws -> Account {
        return try realm.authenticate(credentials: AccessToken(string: identifier))
    }
    
    /**
     Creates a session for a given Subject object and returns the identifier.
     */
    public func createSession(account: Account) -> String {
        let token = CryptoRandom.bytes(16).base64String
        
        var userSession = UserSession(accessToken: token, userId: account.uniqueID)
        try userSession.save()
        
        guard let id = try userSession.save().id else {
            return InvalidSessionError
        }
        
        return token
    }
    
    /**
     Destroys the session for a session identifier.
     */
    public func destroySession(identifier: String) {
        try? cache.delete(identifier)
    }
}
