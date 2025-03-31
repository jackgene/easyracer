import DockerSwift
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import Logging
import XCTest
@testable import EasyRacer

final class EasyRacerTests: XCTestCase {
    lazy var docker = {
        var logger = Logger(label: "docker-client")
        logger.logLevel = .error
        return DockerClient(logger: logger)
    }
    
    func testAllScenarios() async {
        // Set up
        var logger = Logger(label: "docker-client")
        logger.logLevel = .error
        let docker = DockerClient(logger: logger)
        let containerSpec = ContainerSpec(
            config: .init(
                image: "ghcr.io/jamesward/easyracer:latest",
                exposedPorts: [.tcp(8080)]
            ),
            hostConfig: .init(
                portBindings: [
                    .tcp(8080): [.publishTo(hostIp: "0.0.0.0", hostPort: 0)]
                ]
            )
        )
        do {
            _ = try await docker.images.pull(byName: "ghcr.io/jamesward/easyracer:latest")
            let container = try await docker.containers.create(spec: containerSpec)
            try? await docker.containers.start(container.id)
            guard
                let runningContainer = try? await docker.containers.get(container.id)
            else {
                XCTFail("Failed to start container")
                return
            }
            let randomPort = runningContainer.networkSettings.ports["8080/tcp"]!!.first!.hostPort
            let baseURL = URL(string: "http://localhost:\(randomPort)")!
            // Wait for scenario server to start handling HTTP requests
            while true {
                do {
                    _ = try await URLSession.shared.data(from: baseURL)
                    break
                } catch {
                    try? await Task.sleep(nanoseconds: 10_000_000) // 10ms
                    continue
                }
            }
            
            // Test
            let results = await EasyRacer(baseURL: baseURL).scenarios()
            XCTAssertEqual(results.count, 11, "Number of Scenarios")
            for (idx, result) in results.enumerated() {
                XCTAssertEqual(result, "right", "Scenario \(idx + 1)")
            }
            
            // Tear down
            try? await docker.containers.stop(container.id)
        } catch {
            XCTFail("Failed to create container: \(error)")
        }
        
        _ = try? await docker.containers.prune()
        try? await docker.shutdown()
    }
}
