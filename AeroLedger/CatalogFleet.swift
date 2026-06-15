import Foundation

// MARK: - Aircraft catalog (12 models, 3 classes)
enum FleetCatalog {
    static let models: [AircraftModel] = [
        // Regional (runway tier 1)
        AircraftModel(id: "ac_prop48", name: "Skylark P48", cls: .regional,
                      seatsEco: 44, seatsBus: 4, seatsFst: 0, rangeKm: 1200, fuelBurn: 9,
                      purchaseCost: 480_000, leaseWeekly: 5_200, wearRate: 4.0, minRunwayTier: 1),
        AircraftModel(id: "ac_rj70", name: "Aerion RJ70", cls: .regional,
                      seatsEco: 62, seatsBus: 8, seatsFst: 0, rangeKm: 2200, fuelBurn: 13,
                      purchaseCost: 760_000, leaseWeekly: 8_100, wearRate: 3.6, minRunwayTier: 1),
        AircraftModel(id: "ac_rj90", name: "Aerion RJ90", cls: .regional,
                      seatsEco: 84, seatsBus: 10, seatsFst: 0, rangeKm: 3000, fuelBurn: 17,
                      purchaseCost: 1_150_000, leaseWeekly: 11_500, wearRate: 3.4, minRunwayTier: 2),
        AircraftModel(id: "ac_turbo30", name: "Coastal T30", cls: .regional,
                      seatsEco: 30, seatsBus: 0, seatsFst: 0, rangeKm: 900, fuelBurn: 6,
                      purchaseCost: 320_000, leaseWeekly: 3_600, wearRate: 4.4, minRunwayTier: 1),
        // Narrowbody (tier 2)
        AircraftModel(id: "ac_nb150", name: "Meridian 150", cls: .narrowbody,
                      seatsEco: 138, seatsBus: 16, seatsFst: 0, rangeKm: 5200, fuelBurn: 26,
                      purchaseCost: 4_200_000, leaseWeekly: 36_000, wearRate: 2.8, minRunwayTier: 2),
        AircraftModel(id: "ac_nb180", name: "Meridian 180", cls: .narrowbody,
                      seatsEco: 168, seatsBus: 18, seatsFst: 4, rangeKm: 5800, fuelBurn: 30,
                      purchaseCost: 5_400_000, leaseWeekly: 44_000, wearRate: 2.7, minRunwayTier: 2),
        AircraftModel(id: "ac_nb200", name: "Zephyr 200", cls: .narrowbody,
                      seatsEco: 186, seatsBus: 22, seatsFst: 6, rangeKm: 6600, fuelBurn: 34,
                      purchaseCost: 6_900_000, leaseWeekly: 55_000, wearRate: 2.5, minRunwayTier: 3),
        AircraftModel(id: "ac_nbmax", name: "Zephyr MAX", cls: .narrowbody,
                      seatsEco: 204, seatsBus: 24, seatsFst: 8, rangeKm: 7200, fuelBurn: 33,
                      purchaseCost: 8_400_000, leaseWeekly: 66_000, wearRate: 2.2, minRunwayTier: 3),
        // Widebody (tier 3-4)
        AircraftModel(id: "ac_wb280", name: "Atlas 280", cls: .widebody,
                      seatsEco: 246, seatsBus: 40, seatsFst: 12, rangeKm: 11000, fuelBurn: 58,
                      purchaseCost: 18_500_000, leaseWeekly: 142_000, wearRate: 2.0, minRunwayTier: 3),
        AircraftModel(id: "ac_wb350", name: "Atlas 350", cls: .widebody,
                      seatsEco: 298, seatsBus: 52, seatsFst: 16, rangeKm: 13000, fuelBurn: 66,
                      purchaseCost: 24_000_000, leaseWeekly: 182_000, wearRate: 1.9, minRunwayTier: 4),
        AircraftModel(id: "ac_wb400", name: "Continental 400", cls: .widebody,
                      seatsEco: 360, seatsBus: 60, seatsFst: 20, rangeKm: 14500, fuelBurn: 78,
                      purchaseCost: 31_000_000, leaseWeekly: 232_000, wearRate: 1.8, minRunwayTier: 4),
        AircraftModel(id: "ac_wbsuper", name: "Continental Super", cls: .widebody,
                      seatsEco: 460, seatsBus: 76, seatsFst: 28, rangeKm: 15600, fuelBurn: 92,
                      purchaseCost: 42_000_000, leaseWeekly: 308_000, wearRate: 1.7, minRunwayTier: 4),
    ]

    static func model(_ id: String) -> AircraftModel? { models.first { $0.id == id } }
}
