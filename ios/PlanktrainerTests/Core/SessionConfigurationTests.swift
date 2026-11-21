import Testing
@testable import Planktrainer

@Suite struct SessionConfigurationTests {
    @Test(arguments: [(0, 10), (5, 10), (12, 10), (13, 15), (62, 60), (600, 600), (630, 600)])
    func normalizesPlannedSeconds(input: Int, expected: Int) {
        let configuration = SessionConfiguration(plannedSeconds: input, preparationSeconds: 10)
        #expect(configuration.plannedSeconds == expected)
    }

    @Test(arguments: [(0, 5), (12, 10), (13, 15), (61, 60), (90, 60)])
    func normalizesPreparationSeconds(input: Int, expected: Int) {
        let configuration = SessionConfiguration(plannedSeconds: 60, preparationSeconds: input)
        #expect(configuration.preparationSeconds == expected)
    }

    @Test func standardConfiguration() {
        #expect(SessionConfiguration.standard.plannedSeconds == 60)
        #expect(SessionConfiguration.standard.preparationSeconds == 10)
    }
}
