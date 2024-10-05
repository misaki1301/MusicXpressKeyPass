//
//  WebAuthnAccountManager.swift
//  MusicXpressKeyPass
//
//  Created by Paul Frank on 15/06/24.
//

import Foundation
import AuthenticationServices
import os
import _AuthenticationServices_SwiftUI
import SwordWard

private let domain = "0774-2001-1388-19e9-8f87-2c36-13d6-4004-5a2b.ngrok-free.app/"
private let createUserEndpoint = "https://\(domain)signup"
private let signInUserEndpoint = "https://\(domain)authenticate"
private let registerBeginEndpoint = "https://\(domain)makeCredential"
private let signOutEndpoint = "https://\(domain)signout"
private let deleteEndpoint = "https://\(domain)deleteCredential"

public extension Logger {
	static let authorization = Logger(subsystem: "MusicXpressKeyPass", category: "Accounts")
}

public enum AuthorizationHandlingError: Error {
	case unknownAuthorizationResult(ASAuthorizationResult)
	case otherError
}

extension AuthorizationHandlingError: LocalizedError {
	public var errorDescription: String? {
		switch self {
			case .unknownAuthorizationResult:
				return NSLocalizedString("Received an unknown authorization result.",
										 comment: "Human readable description of receiving an unknown authorization result.")
			case .otherError:
				return NSLocalizedString("Encountered an error handling the authorization result.",
										 comment: "Human readable description of an unknown error while handling the authorization result.")
		}
	}
}

@MainActor
public final class AuthorizationManager: NSObject, ObservableObject, ASAuthorizationControllerDelegate {
	
	@Published var currentUser: User? = nil
	
	public weak var presentationContextProvider: ASAuthorizationControllerPresentationContextProviding?
	
	public var isSIgnedIn: Bool {
		currentUser != nil
	}
	
	private static let relyingPartyIdentifier = "0774-2001-1388-19e9-8f87-2c36-13d6-4004-5a2b.ngrok-free.app"
	
	private func signInRequests() async -> [ASAuthorizationRequest] {
		await [passkeyAssertionRequest(), ASAuthorizationPasswordProvider().createRequest()]
	}
	
	private func passkeyChallenge() async -> Data {
		Data("passkey challenge".utf8)
	}
	
	private func passkeyAssertionRequest() async -> ASAuthorizationRequest {
		await ASAuthorizationPlatformPublicKeyCredentialProvider(relyingPartyIdentifier: Self.relyingPartyIdentifier)
			.createCredentialAssertionRequest(challenge: passkeyChallenge())
	}
	
	private func passkeyRegistrationRequest(username: String) async -> ASAuthorizationRequest {
		await ASAuthorizationPlatformPublicKeyCredentialProvider(relyingPartyIdentifier: Self.relyingPartyIdentifier)
			.createCredentialRegistrationRequest(challenge: passkeyChallenge(), name: username, userID: Data(username.utf8))
	}
	
	public func registerUserCredential(authorizationController: AuthorizationController, username: String) async {
		guard var url = URL(string: createUserEndpoint) else {
			return
		}
		url.append(queryItems: [
			URLQueryItem(name: "username", value: username)
		])
		let result = try? await URLSession.shared.data(from: url)
		guard let (_, httpResponse) = result else {
			return
		}
		guard let registerURl = URL(string: registerBeginEndpoint) else {
			return
		}
		let resulRegister = try? await URLSession.shared.data(from: registerURl)
		guard let (dataRegister, _) = resulRegister else {
			return
		}
		guard let decodedRegister = try? JSONDecoder().decode(BeginWebAuthnRegistrationResponse.self, from: dataRegister) else {
			return
		}
		await beginWebAuthRegistration(response: decodedRegister, authorizationController: authorizationController)
	}
	
	// MARK: - Passkey Registration backend test
	func beginWebAuthRegistration(response: BeginWebAuthnRegistrationResponse, authorizationController: AuthorizationController, options: ASAuthorizationController.RequestOptions = []) async {
		let challengeResponseString = response.challenge
		let usernameDecoded = response.user.name
		let userIdDecoded = response.user.id
		
		let userId = Data(userIdDecoded.utf8)
		guard let challengeBase64EncodedData = challengeResponseString.base64URLDecodedData() else {
			return
		}
		
		let publicKeyCredentialProvider = 
		ASAuthorizationPlatformPublicKeyCredentialProvider(relyingPartyIdentifier: Self.relyingPartyIdentifier)
		let registrationRequest = publicKeyCredentialProvider.createCredentialRegistrationRequest(challenge: challengeBase64EncodedData, name: usernameDecoded, userID: userId)
		
		do {
			let authorizationResult = try await authorizationController.performRequests([registrationRequest], options: options)
			try await self.handleAuthorizationResult(authorizationResult, username: usernameDecoded)
		} catch let authorizationError as ASAuthorizationError where authorizationError.code == .canceled {
				// The user cancelled the registration.
			Logger.authorization.log("The user cancelled passkey registration.")
		} catch let authorizationError as ASAuthorizationError {
				// Some other error occurred occurred during registration.
			Logger.authorization.error("Passkey registration failed. Error: \(authorizationError.localizedDescription)")
		} catch AuthorizationHandlingError.unknownAuthorizationResult(let authorizationResult) {
				// Received an unknown response.
			Logger.authorization.error("""
   Passkey registration handling failed. \
   Received an unknown result: \(String(describing: authorizationResult))
   """)
		} catch {
				// Some other error occurred while handling the registration.
			Logger.authorization.error("""
   Passkey registration handling failed. \
   Caught an unknown error during passkey registration or handling: \(error.localizedDescription).
   """)
		}
		
	}
	
	// MARK: - Register Passkey - local test
	public func createPasskeyAccount(authorizationController: AuthorizationController, username: String, options: ASAuthorizationController.RequestOptions = []) async {
		do {
			let authorizationResult = try await authorizationController.performRequests(
				[passkeyRegistrationRequest(username: username)],
				options: options)
			try await handleAuthorizationResult(authorizationResult, username: username)
		} catch let authorizationError as ASAuthorizationError where authorizationError.code == .canceled {
				// The user cancelled the registration.
			Logger.authorization.log("The user cancelled passkey registration.")
		} catch let authorizationError as ASAuthorizationError {
				// Some other error occurred occurred during registration.
			Logger.authorization.error("Passkey registration failed. Error: \(authorizationError.localizedDescription)")
		} catch AuthorizationHandlingError.unknownAuthorizationResult(let authorizationResult) {
				// Received an unknown response.
			Logger.authorization.error("""
			Passkey registration handling failed. \
			Received an unknown result: \(String(describing: authorizationResult))
			""")
		} catch {
				// Some other error occurred while handling the registration.
			Logger.authorization.error("""
			Passkey registration handling failed. \
			Caught an unknown error during passkey registration or handling: \(error.localizedDescription).
			""")
		}
	}
	
	
	// MARK: - Login PassKey - local test
	public func signIntoPassKeyAccount(authorizationController: AuthorizationController, username: String, options: ASAuthorizationController.RequestOptions = []) async {
		do {
			let authorizationResult = try await authorizationController.performRequests(signInRequests(), options: options)
			try await handleAuthorizationResult(authorizationResult, username: username)
		} catch let authorizationError as ASAuthorizationError where authorizationError.code == .canceled {
				// The user cancelled the registration.
			Logger.authorization.log("The user cancelled passkey registration.")
		} catch let authorizationError as ASAuthorizationError {
				// Some other error occurred occurred during registration.
			Logger.authorization.error("Passkey registration failed. Error: \(authorizationError.localizedDescription)")
		} catch AuthorizationHandlingError.unknownAuthorizationResult(let authorizationResult) {
				// Received an unknown response.
			Logger.authorization.error("""
			Passkey registration handling failed. \
			Received an unknown result: \(String(describing: authorizationResult))
			""")
		} catch {
				// Some other error occurred while handling the registration.
			Logger.authorization.error("""
			Passkey registration handling failed. \
			Caught an unknown error during passkey registration or handling: \(error.localizedDescription).
			""")
		}
	}
	
	// MARK: - Handle the results.
	private func handleAuthorizationResult(_ authorizationResult: ASAuthorizationResult, username: String? = nil) async throws {
		switch authorizationResult {
			case let .password(passwordCredential):
				Logger.authorization.log("Password authorization succeeded: \(passwordCredential)")
				//currentUser = .authenticated(username: passwordCredential.user)
			case let .passkeyAssertion(passkeyAssertion):
					// The login was successful.
				Logger.authorization.log("Passkey authorization succeeded: \(passkeyAssertion)")
				guard let username = String(bytes: passkeyAssertion.userID, encoding: .utf8) else {
					fatalError("Invalid credential: \(passkeyAssertion)")
				}
				//currentUser = .authenticated(username: username)
			case let .passkeyRegistration(passkeyRegistration):
				// The registration was successful.
				Logger.authorization.log("Passkey registration succeeded: \(passkeyRegistration)")
				// MARK: - GENERATED NEW PASSKEY, USER CALL API
				let credentialIDObjectBase64 = passkeyRegistration.credentialID.base64EncodedString()
				let rawIdObject = passkeyRegistration.credentialID.base64EncodedString()
				let clientDataJsonBase64 = passkeyRegistration.rawClientDataJSON.base64EncodedString()
				guard let attestationObjectBase64 = passkeyRegistration.rawAttestationObject?.base64EncodedString() else {
					print("Error getting attestation base64")
					return
				}
				
				let responseObject: [String: Any] = [
					"clientDataJSON": clientDataJsonBase64,
					"attestationObject": attestationObjectBase64
				]
				
				let params: [String: Any] = [
					"id": credentialIDObjectBase64,
					"rawId": rawIdObject,
					"response": responseObject,
					"type": "public-key"
				]
				
				var request = URLRequest(url: URL(string: registerBeginEndpoint)!, cachePolicy: .reloadIgnoringLocalCacheData)
				request.httpMethod = "POST"
				guard let jsonBody = try? JSONSerialization.data(withJSONObject: params, options: .prettyPrinted) else { return }
				//HTTP Headers
				request.addValue("application/json", forHTTPHeaderField: "Content-Type")
				request.addValue("application/json", forHTTPHeaderField: "Accept")
				request.httpBody = jsonBody
				
				var result = try? await URLSession.shared.data(for: request)
				guard let (data, response) = result else {
					return
				}
				// TODO: USER CAN BE LOGGED IN
				guard let httpResponse = response as? HTTPURLResponse, 200..<304 ~= httpResponse.statusCode else {
					print("bad error status http")
					return
				}
			default:
				Logger.authorization.error("Received an unknown authorization result.")
					// Throw an error and return to the caller.
				throw AuthorizationHandlingError.unknownAuthorizationResult(authorizationResult)
		}
		
			// In a real app, call the code at this location to obtain and save an authentication token to the keychain and sign in the user.
	}
}

extension String {
	func base64URLDecodedData() -> Data? {
		var base64 = self
			.replacingOccurrences(of: "-", with: "+")
			.replacingOccurrences(of: "_", with: "/")
		
		let paddingLength = (4 - base64.count % 4) % 4
		base64 += String(repeating: "=", count: paddingLength)
		return Data(base64Encoded: base64)
	}
}
