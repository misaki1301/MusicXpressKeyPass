//
//  User.swift
//  MusicXpressKeyPass
//
//  Created by Paul Frank on 15/06/24.
//

import Foundation

public enum UserLocal {
	case `default`
	case authenticated(username: String)
	
	public init(username: String) {
		self = .authenticated(username: username)
	}
}
