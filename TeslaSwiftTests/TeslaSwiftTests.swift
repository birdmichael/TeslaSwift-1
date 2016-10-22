//
//  TeslaSwiftTests.swift
//  TeslaSwiftTests
//
//  Created by Joao Nunes on 04/03/16.
//  Copyright © 2016 Joao Nunes. All rights reserved.
//

import XCTest
@testable import TeslaSwift
import OHHTTPStubs

class TeslaSwiftTests: XCTestCase {
	
	let headers = ["Content-Type" as NSObject :"application/json" as AnyObject]
	
	override func setUp() {
		super.setUp()
		// Put setup code here. This method is called before the invocation of each test method in the class.
		
		let stubPath = OHPathForFile("Authentication.json", type(of: self))
		_ = stub(condition: isPath(Endpoint.authentication.path)) {
			_ in
			return fixture(filePath: stubPath!, headers: self.headers)
		}
		
		let path2 = OHPathForFile("Vehicles.json", type(of: self))
		_ = stub(condition: isPath(Endpoint.vehicles.path)) {
			_ in
			return fixture(filePath: path2!, headers: self.headers)
		}
	}
	
	override func tearDown() {
		// Put teardown code here. This method is called after the invocation of each test method in the class.
		super.tearDown()
		
	}
	
	func testAuthenticate() {
		
		let expection = expectation(description: "All Done")
		
		let service = TeslaSwift()
		service.useMockServer = true
		
		service.authenticate("user", password: "pass")
			.then { (response) -> Void in
				
				XCTAssertEqual(response.accessToken, "abc123-mock")
				expection.fulfill()
			}.catch { (error) in
				print(error)
		}
		
		waitForExpectations(timeout: 2, handler: nil)
		
	}
	
	func testAuthenticationFailed() {
		
		let stubPath = OHPathForFile("AuthenticationFailed.json", type(of: self))
		_ = stub(condition: isPath(Endpoint.authentication.path)) {
			_ in
			return fixture(filePath: stubPath!, status: 401, headers: self.headers)
		}
		
		let expection = expectation(description: "All Done")
		
		let service = TeslaSwift()
		service.useMockServer = true
		
		service.authenticate("user", password: "pass")
			.then { (response) -> Void in
				
				XCTFail("Authentication must fail")
				expection.fulfill()
			}.catch { (error) in
				if case TeslaError.authenticationFailed = error {
					
				} else {
					XCTFail("Authentication must fail")
				}
				expection.fulfill()
		}
		
		waitForExpectations(timeout: 2, handler: nil)
		
	}
	
	func testReuseToken() {
		
		let expection = expectation(description: "All Done")
		
		let service = TeslaSwift()
		service.useMockServer = true
		
		_ = service.authenticate("user", password: "pass")
			.then {
				(_) -> Void in
				
				service.checkToken().then { (response) -> Void in
					
					XCTAssertTrue(response)
					expection.fulfill()
					
					}.catch { (error) in
						XCTFail("Token is not valid: \((error as NSError).description)")
				}
				
		}
		
		waitForExpectations(timeout: 2, handler: nil)
		
	}
	
	func testGetVehicles() {
		
		let expection = expectation(description: "All Done")
		
		let service = TeslaSwift()
		service.useMockServer = true
		
		_ = service.authenticate("user", password: "pass")
			.then {
				(_) -> Void in
				service.getVehicles()
					.then {
						(response) -> Void in
						
						XCTAssertEqual(response[0].displayName, "mockCar")
						
						expection.fulfill()
						
					}.catch{ (error) in
						print(error)
						XCTFail((error as NSError).description)
				}
		}
		
		waitForExpectations(timeout: 2, handler: nil)
		
	}
	
	func testGetVehicleState() {
		
		let stubPath = OHPathForFile("MobileAccess.json", type(of: self))
		_ = stub(condition: isPath(Endpoint.mobileAccess(vehicleID: 321).path)) {
			_ in
			return fixture(filePath: stubPath!, headers: self.headers)
		}
		let stubPath2 = OHPathForFile("ChargeState.json", type(of: self))
		_ = stub(condition: isPath(Endpoint.chargeState(vehicleID: 321).path)) {
			_ in
			return fixture(filePath: stubPath2!, headers: self.headers)
		}
		let stubPath3 = OHPathForFile("ClimateSettings.json", type(of: self))
		_ = stub(condition: isPath(Endpoint.climateState(vehicleID: 321).path)) {
			_ in
			return fixture(filePath: stubPath3!, headers: self.headers)
		}
		let stubPath4 = OHPathForFile("DriveState.json", type(of: self))
		_ = stub(condition: isPath(Endpoint.driveState(vehicleID: 321).path)) {
			_ in
			return fixture(filePath: stubPath4!, headers: self.headers)
		}
		let stubPath5 = OHPathForFile("GuiSettings.json", type(of: self))
		_ = stub(condition: isPath(Endpoint.guiSettings(vehicleID: 321).path)) {
			_ in
			return fixture(filePath: stubPath5!, headers: self.headers)
		}
		let stubPath6 = OHPathForFile("VehicleState.json", type(of: self))
		_ = stub(condition: isPath(Endpoint.vehicleState(vehicleID: 321).path)) {
			_ in
			return fixture(filePath: stubPath6!, headers: self.headers)
		}
		
		let expection = expectation(description: "All Done")
		
		let service = TeslaSwift()
		service.useMockServer = true
		
		service.authenticate("user", password: "pass").then { (token) in
			service.getVehicles()
			}.then { (vehicles)  in
				service.getVehicleStatus(vehicles[0])
			}.then { (response) -> Void in
				
				XCTAssertEqual(response.mobileAccess, false)
				XCTAssertEqual(response.chargeState?.chargingState, .Complete)
				XCTAssertEqual(response.chargeState?.batteryRange?.miles, 200.0)
				XCTAssertEqual(response.climateState?.insideTemperature?.celsius,18.0)
				XCTAssertEqual(response.driveState?.position?.course,10.0)
				XCTAssertEqual(response.guiSettings?.distanceUnits,"km/hr")
				XCTAssertEqual(response.vehicleState?.darkRims, true)
				
				expection.fulfill()
			}.catch { (error) in
				print(error)
				XCTFail((error as NSError).description)
		}
		
		waitForExpectations(timeout: 2, handler: nil)
		
	}
	
	func testCommandWakeUp() {
		
		let stubPath = OHPathForFile("WakeUp.json", type(of: self))
		_ = stub(condition: isPath(Endpoint.command(vehicleID: 321, command: .wakeUp).path)) {
			_ in
			return fixture(filePath: stubPath!, headers: self.headers)
		}
		
		let expection = expectation(description: "All Done")
		
		let service = TeslaSwift()
		service.useMockServer = true
		
		service.authenticate("user", password: "pass").then { (token) in
			service.getVehicles()
			}.then { (vehicles)  in
				service.sendCommandToVehicle(vehicles[0], command: .wakeUp)
			}.then { (response) -> Void in
				
				XCTAssertEqual(response.result, false)
				XCTAssertEqual(response.reason, "Test wakeup")
				
				expection.fulfill()
			}.catch { (error) in
				print(error)
				XCTFail((error as NSError).description)
		}
		
		waitForExpectations(timeout: 2, handler: nil)
	}
	
	func testCommandValetMode() {
		
		let options = ValetCommandOptions(valetActivated: true, pin: "1234")
		
		let stubPath = OHPathForFile("SetValetMode.json", type(of: self))
		_ = stub(condition: isPath(Endpoint.command(vehicleID: 321, command: .valetMode(options: options)).path)) {
			_ in
			return fixture(filePath: stubPath!, headers: self.headers)
		}

		let expection = expectation(description: "All Done")
		
		let service = TeslaSwift()
		service.useMockServer = true
		
		service.authenticate("user", password: "pass").then { (token) in
			service.getVehicles()
			}.then { (vehicles) in
				service.sendCommandToVehicle(vehicles[0], command: .valetMode(options: options))
			}.then { (response) -> Void in
				
				XCTAssertEqual(response.result, false)
				XCTAssertEqual(response.reason, "Test valet")
				
				expection.fulfill()
			}.catch { (error) in
				print(error)
				XCTFail((error as NSError).description)
		}
		
		waitForExpectations(timeout: 2, handler: nil)
	}
	
	func testCommandResetValetPin() {
		
		let stubPath = OHPathForFile("ResetValetPin.json", type(of: self))
		_ = stub(condition: isPath(Endpoint.command(vehicleID: 321, command: .resetValetPin).path)) {
			_ in
			return fixture(filePath: stubPath!, headers: self.headers)
		}
		
		let expection = expectation(description: "All Done")
		
		let service = TeslaSwift()
		service.useMockServer = true
		
		service.authenticate("user", password: "pass").then { (token) in
			service.getVehicles()
			}.then { (vehicles)  in
				service.sendCommandToVehicle(vehicles[0], command: .resetValetPin)
			}.then { (response) -> Void in
				
				XCTAssertEqual(response.result, false)
				XCTAssertEqual(response.reason, "Test resetValet")
				
				expection.fulfill()
			}.catch { (error) in
				print(error)
				XCTFail((error as NSError).description)
		}
		
		waitForExpectations(timeout: 2, handler: nil)
	}
	
	func testCommandOpenChargePort() {
		
		let stubPath = OHPathForFile("OpenChargeDoor.json", type(of: self))
		_ = stub(condition: isPath(Endpoint.command(vehicleID: 321, command: .openChargeDoor).path)) {
			_ in
			return fixture(filePath: stubPath!, headers: self.headers)
		}
		
		let expection = expectation(description: "All Done")
		
		let service = TeslaSwift()
		service.useMockServer = true
		
		service.authenticate("user", password: "pass").then { (token) in
			service.getVehicles()
			}.then { (vehicles)  in
				service.sendCommandToVehicle(vehicles[0], command: .openChargeDoor)
			}.then { (response) -> Void in
				
				XCTAssertEqual(response.result, false)
				XCTAssertEqual(response.reason, "Test open charge door")
				
				expection.fulfill()
			}.catch { (error) in
				print(error)
				XCTFail((error as NSError).description)
		}
		
		waitForExpectations(timeout: 2, handler: nil)
	}
	
	func testCommandChargeStandard() {
		
		let stubPath = OHPathForFile("ChargeLimitStandard.json", type(of: self))
		_ = stub(condition: isPath(Endpoint.command(vehicleID: 321, command: .chargeLimitStandard).path)) {
			_ in
			return fixture(filePath: stubPath!, headers: self.headers)
		}
		
		let expection = expectation(description: "All Done")
		
		let service = TeslaSwift()
		service.useMockServer = true
		
		service.authenticate("user", password: "pass").then { (token) in
			service.getVehicles()
			}.then { (vehicles)  in
				service.sendCommandToVehicle(vehicles[0], command: .chargeLimitStandard)
			}.then { (response) -> Void in
				
				XCTAssertEqual(response.result, false)
				XCTAssertEqual(response.reason, "Test charge standard")
				
				expection.fulfill()
			}.catch { (error) in
				print(error)
				XCTFail((error as NSError).description)
		}
		
		waitForExpectations(timeout: 2, handler: nil)
	}
	
	func testCommandChargeMaxRate() {
		
		let stubPath = OHPathForFile("ChargeLimitMaxRange.json", type(of: self))
		_ = stub(condition: isPath(Endpoint.command(vehicleID: 321, command: .chargeLimitMaxRange).path)) {
			_ in
			return fixture(filePath: stubPath!, headers: self.headers)
		}

		let expection = expectation(description: "All Done")
		
		let service = TeslaSwift()
		service.useMockServer = true
		
		service.authenticate("user", password: "pass").then { (token) in
			service.getVehicles()
			}.then { (vehicles)  in
				service.sendCommandToVehicle(vehicles[0], command: .chargeLimitMaxRange)
			}.then { (response) -> Void in
				
				XCTAssertEqual(response.result, false)
				XCTAssertEqual(response.reason, "Test charge max range")
				
				expection.fulfill()
			}.catch { (error) in
				print(error)
				XCTFail((error as NSError).description)
		}
		
		waitForExpectations(timeout: 2, handler: nil)
	}
	
	func testCommandChargePercentage() {
		
		let stubPath = OHPathForFile("ChargeLimitPercentage.json", type(of: self))
		_ = stub(condition: isPath("/api/1/vehicles/321/command/set_charge_limit")) {
			_ in
			return fixture(filePath: stubPath!, headers: self.headers)
		}
		
		let expection = expectation(description: "All Done")
		
		let service = TeslaSwift()
		service.useMockServer = true
		
		service.authenticate("user", password: "pass").then { (token) in
			service.getVehicles()
			}.then { (vehicles)  in
				service.sendCommandToVehicle(vehicles[0], command: .chargeLimitPercentage(limit: 10))
			}.then { (response) -> Void in
				
				XCTAssertEqual(response.result, false)
				XCTAssertEqual(response.reason, "Test charge percentage")
				
				expection.fulfill()
			}.catch { (error) in
				print(error)
				XCTFail((error as NSError).description)
		}
		
		waitForExpectations(timeout: 2, handler: nil)
	}
	
	func testCommandStartCharging() {
		
		let stubPath = OHPathForFile("StartCharging.json", type(of: self))
		_ = stub(condition: isPath(Endpoint.command(vehicleID: 321, command: .startCharging).path)) {
			_ in
			return fixture(filePath: stubPath!, headers: self.headers)
		}
		
		let expection = expectation(description: "All Done")
		
		let service = TeslaSwift()
		service.useMockServer = true
		
		service.authenticate("user", password: "pass").then { (token) in
			service.getVehicles()
			}.then { (vehicles)  in
				service.sendCommandToVehicle(vehicles[0], command: .startCharging)
			}.then { (response) -> Void in
				
				XCTAssertEqual(response.result, false)
				XCTAssertEqual(response.reason, "Test start charging")
				
				expection.fulfill()
			}.catch { (error) in
				print(error)
				XCTFail((error as NSError).description)
		}
		
		waitForExpectations(timeout: 2, handler: nil)
	}
	
	func testCommandStopCharging() {
		
		let stubPath = OHPathForFile("StopCharging.json", type(of: self))
		_ = stub(condition: isPath(Endpoint.command(vehicleID: 321, command: .stopCharging).path)) {
			_ in
			return fixture(filePath: stubPath!, headers: self.headers)
		}
		
		let expection = expectation(description: "All Done")
		
		let service = TeslaSwift()
		service.useMockServer = true
		
		service.authenticate("user", password: "pass").then { (token) in
			service.getVehicles()
			}.then { (vehicles)  in
				service.sendCommandToVehicle(vehicles[0], command: .stopCharging)
			}.then { (response) -> Void in
				
				XCTAssertEqual(response.result, false)
				XCTAssertEqual(response.reason, "Test stop charging")
				
				expection.fulfill()
			}.catch { (error) in
				print(error)
				XCTFail((error as NSError).description)
		}
		
		waitForExpectations(timeout: 2, handler: nil)
	}
	
	func testCommandFlashLights() {
		
		let stubPath = OHPathForFile("FlashLights.json", type(of: self))
		_ = stub(condition: isPath(Endpoint.command(vehicleID: 321, command: .flashLights).path)) {
			_ in
			return fixture(filePath: stubPath!, headers: self.headers)
		}
		
		let expection = expectation(description: "All Done")
		
		let service = TeslaSwift()
		service.useMockServer = true
		
		service.authenticate("user", password: "pass").then { (token) in
			service.getVehicles()
			}.then { (vehicles)  in
				service.sendCommandToVehicle(vehicles[0], command: .flashLights)
			}.then { (response) -> Void in
				
				XCTAssertEqual(response.result, false)
				XCTAssertEqual(response.reason, "Test FlashLights")
				
				expection.fulfill()
			}.catch { (error) in
				print(error)
				XCTFail((error as NSError).description)
		}
		
		waitForExpectations(timeout: 2, handler: nil)
	}
	
	func testCommandHonkHorn() {
		
		let stubPath = OHPathForFile("HonkHorn.json", type(of: self))
		_ = stub(condition: isPath(Endpoint.command(vehicleID: 321, command: .honkHorn).path)) {
			_ in
			return fixture(filePath: stubPath!, headers: self.headers)
		}
		
		let expection = expectation(description: "All Done")
		
		let service = TeslaSwift()
		service.useMockServer = true
		
		service.authenticate("user", password: "pass").then { (token) in
			service.getVehicles()
			}.then { (vehicles)  in
				service.sendCommandToVehicle(vehicles[0], command: .honkHorn)
			}.then { (response) -> Void in
				
				XCTAssertEqual(response.result, false)
				XCTAssertEqual(response.reason, "Test HonkHorn")
				
				expection.fulfill()
			}.catch { (error) in
				print(error)
				XCTFail((error as NSError).description)
		}
		
		waitForExpectations(timeout: 2, handler: nil)
	}
	
	func testCommandUnlockDoors() {
		
		let stubPath = OHPathForFile("UnlockDoors.json", type(of: self))
		_ = stub(condition: isPath(Endpoint.command(vehicleID: 321, command: .unlockDoors).path)) {
			_ in
			return fixture(filePath: stubPath!, headers: self.headers)
		}
		
		let expection = expectation(description: "All Done")
		
		let service = TeslaSwift()
		service.useMockServer = true
		
		service.authenticate("user", password: "pass").then { (token) in
			service.getVehicles()
			}.then { (vehicles)  in
				service.sendCommandToVehicle(vehicles[0], command: .unlockDoors)
			}.then { (response) -> Void in
				
				XCTAssertEqual(response.result, false)
				XCTAssertEqual(response.reason, "Test UnlockDoors")
				
				expection.fulfill()
			}.catch { (error) in
				print(error)
				XCTFail((error as NSError).description)
		}
		
		waitForExpectations(timeout: 2, handler: nil)
	}
	
	func testCommandLockDoors() {
		
		let stubPath = OHPathForFile("LockDoors.json", type(of: self))
		_ = stub(condition: isPath(Endpoint.command(vehicleID: 321, command: .lockDoors).path)) {
			_ in
			return fixture(filePath: stubPath!, headers: self.headers)
		}
		
		let expection = expectation(description: "All Done")
		
		let service = TeslaSwift()
		service.useMockServer = true
		
		service.authenticate("user", password: "pass").then { (token) in
			service.getVehicles()
			}.then { (vehicles)  in
				service.sendCommandToVehicle(vehicles[0], command: .lockDoors)
			}.then { (response) -> Void in
				
				XCTAssertEqual(response.result, false)
				XCTAssertEqual(response.reason, "Test LockDoors")
				
				expection.fulfill()
			}.catch { (error) in
				print(error)
				XCTFail((error as NSError).description)
		}
		
		waitForExpectations(timeout: 2, handler: nil)
	}
	
	func testCommandSetTemperature() {
		
		let stubPath = OHPathForFile("SetTemperature.json", type(of: self))
		_ = stub(condition: isPath("/api/1/vehicles/321/command/set_temps")) {
			_ in
			return fixture(filePath: stubPath!, headers: self.headers)
		}
		
		let expection = expectation(description: "All Done")
		
		let service = TeslaSwift()
		service.useMockServer = true
		
		service.authenticate("user", password: "pass").then { (token) in
			service.getVehicles()
			}.then { (vehicles)  in
				service.sendCommandToVehicle(vehicles[0], command: .setTemperature(driverTemperature: 22.0, passangerTemperature: 23.0))
			}.then { (response) -> Void in
				
				XCTAssertEqual(response.result, false)
				XCTAssertEqual(response.reason, "Test SetTemperature")
				
				expection.fulfill()
			}.catch { (error) in
				print(error)
				XCTFail((error as NSError).description)
		}
		
		waitForExpectations(timeout: 2, handler: nil)
	}
	
	func testCommandStartAutoConditioning() {
		
		let stubPath = OHPathForFile("StartAutoConditioning.json", type(of: self))
		_ = stub(condition: isPath(Endpoint.command(vehicleID: 321, command: .startAutoConditioning).path)) {
			_ in
			return fixture(filePath: stubPath!, headers: self.headers)
		}
		
		let expection = expectation(description: "All Done")
		
		let service = TeslaSwift()
		service.useMockServer = true
		
		service.authenticate("user", password: "pass").then { (token) in
			service.getVehicles()
			}.then { (vehicles)  in
				service.sendCommandToVehicle(vehicles[0], command: .startAutoConditioning)
			}.then { (response) -> Void in
				
				XCTAssertEqual(response.result, false)
				XCTAssertEqual(response.reason, "Test StartAutoConditioning")
				
				expection.fulfill()
			}.catch { (error) in
				print(error)
				XCTFail((error as NSError).description)
		}
		
		waitForExpectations(timeout: 2, handler: nil)
	}
	
	func testCommandStopAutoConditioning() {
		
		let stubPath = OHPathForFile("StopAutoConditioning.json", type(of: self))
		_ = stub(condition: isPath(Endpoint.command(vehicleID: 321, command: .stopAutoConditioning).path)) {
			_ in
			return fixture(filePath: stubPath!, headers: self.headers)
		}
		
		let expection = expectation(description: "All Done")
		
		let service = TeslaSwift()
		service.useMockServer = true
		
		service.authenticate("user", password: "pass").then { (token) in
			service.getVehicles()
			}.then { (vehicles)  in
				service.sendCommandToVehicle(vehicles[0], command: .stopAutoConditioning)
			}.then { (response) -> Void in
				
				XCTAssertEqual(response.result, false)
				XCTAssertEqual(response.reason, "Test StopAutoConditioning")
				
				expection.fulfill()
			}.catch { (error) in
				print(error)
				XCTFail((error as NSError).description)
		}
		
		waitForExpectations(timeout: 2, handler: nil)
	}
	
	func testCommandSetSunRoof() {
		
		let stubPath = OHPathForFile("SetSunRoof.json", type(of: self))
		_ = stub(condition: isPath("/api/1/vehicles/321/command/sun_roof_control")) {
			_ in
			return fixture(filePath: stubPath!, headers: self.headers)
		}
		
		let expection = expectation(description: "All Done")
		
		let service = TeslaSwift()
		service.useMockServer = true
		
		service.authenticate("user", password: "pass").then { (token) in
			service.getVehicles()
			}.then { (vehicles)  in
				service.sendCommandToVehicle(vehicles[0], command: .setSunRoof(state: .Open, percentage: 20.0))
			}.then { (response) -> Void in
				
				XCTAssertEqual(response.result, false)
				XCTAssertEqual(response.reason, "Test SetSunRoof")
				
				expection.fulfill()
			}.catch { (error) in
				print(error)
				XCTFail((error as NSError).description)
		}
		
		waitForExpectations(timeout: 2, handler: nil)
	}
	
	func testCommandStartVehicle() {
		
		let stubPath = OHPathForFile("StartVehicle.json", type(of: self))
		_ = stub(condition: isPath("/api/1/vehicles/321/command/remote_start_drive")) {
			_ in
			return fixture(filePath: stubPath!, headers: self.headers)
		}
		
		let expection = expectation(description: "All Done")
		
		let service = TeslaSwift()
		service.useMockServer = true
		
		service.authenticate("user", password: "pass").then { (token) in
			service.getVehicles()
			}.then { (vehicles)  in
				service.sendCommandToVehicle(vehicles[0], command: .startVehicle(password: "pass"))
			}.then { (response) -> Void in
				
				XCTAssertEqual(response.result, false)
				XCTAssertEqual(response.reason, "Test StartVehicle")
				
				expection.fulfill()
			}.catch { (error) in
				print(error)
				XCTFail((error as NSError).description)
		}
		
		waitForExpectations(timeout: 2, handler: nil)
	}
	
	func testCommandOpenTrunk() {
		
		let options = OpenTrunkOptions.Rear
		
		let stubPath = OHPathForFile("OpenTrunk.json", type(of: self))
		_ = stub(condition: isPath(Endpoint.command(vehicleID: 321, command: .openTrunk(options: options)).path)) {
			_ in
			return fixture(filePath: stubPath!, headers: self.headers)
		}
		
		let expection = expectation(description: "All Done")
		
		let service = TeslaSwift()
		service.useMockServer = true
		
		service.authenticate("user", password: "pass").then { (token) in
			service.getVehicles()
			}.then { (vehicles) in
				service.sendCommandToVehicle(vehicles[0], command: .openTrunk(options: options))
			}.then { (response) -> Void in
				
				XCTAssertEqual(response.result, false)
				XCTAssertEqual(response.reason, "Test OpenTrunk")
				
				expection.fulfill()
			}.catch { (error) in
				print(error)
				XCTFail((error as NSError).description)
		}
		
		waitForExpectations(timeout: 2, handler: nil)
	}
}
