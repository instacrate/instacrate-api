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

    private let realm: Realm
    
    public init(realm: Realm) {
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
        try? userSession.save()
        
        assert(userSession.id != nil, "Expected user session to have an id after saving")
        
        return token
    }
    
    /**
     Destroys the session for a session identifier.
     */
    public func destroySession(identifier: String) {
        try? UserSession.query().filter("access_token", identifier).first()?.delete()
    }
}
