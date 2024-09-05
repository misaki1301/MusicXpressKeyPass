//
//  BeginWebAuthnRegistrationResponse.swift
//  MusicXpressKeyPass
//
//  Created by Paul Frank on 17/06/24.
//

import Foundation

struct BeginWebAuthnRegistrationResponse: Codable {
	let rp: Rp
	let timeout: Int
	let attestation: String
	let pubKeyCredParams: [PubKeyCredParam]
	let challenge: String
	let user: User
}

struct PubKeyCredParam: Codable {
	let type: String
	let alg: Int
}

struct Rp: Codable {
	let id, name: String
}

struct User: Codable {
	let id, name, displayName: String
}
