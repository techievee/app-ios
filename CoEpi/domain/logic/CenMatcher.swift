import Foundation
import os.log

protocol CenMatcher {
    func hasMatches(key: CENKey, maxTimestamp: Int64) -> Bool
    func matchLocalFirst(keys: [CENKey], maxTimestamp: Int64) -> [CENKey]
}

class CenMatcherImpl: CenMatcher {
    
    private let cenRepo: CENRepo // TODO decouple from DB
    private let cenLogic: CenLogic

    init(cenRepo: CENRepo, cenLogic: CenLogic) {
        self.cenRepo = cenRepo
        self.cenLogic = cenLogic
    }

    func hasMatches(key: CENKey, maxTimestamp: Int64) -> Bool {
        !match(key: key, maxTimestamp: maxTimestamp).isEmpty
    }
    
    func matchLocalFirst(keys: [CENKey], maxTimestamp: Int64) -> [CENKey] {
        let CENLifetimeInSeconds = 15*60   // every 15 mins a new CEN is generated
        
        let modulus = maxTimestamp % Int64(CENLifetimeInSeconds)
        
        let roundedMaxTimestamp = maxTimestamp - modulus
        let minTimestamp: Int64 = roundedMaxTimestamp - 7*24*60*60
        
        
        let localCens: [CEN] = cenRepo.loadCensForTimeInterval(start: minTimestamp, end: maxTimestamp)
        print("num local cens = %@", localCens.count)
        
        var matchedKeys : [CENKey] = []
        
        for localCen in localCens {
            print(localCen.timestamp)
            let mod = localCen.timestamp % Int64(CENLifetimeInSeconds)
            let roundedLocalTimestamp = localCen.timestamp - mod
            print("\(localCen.timestamp) -> \(roundedLocalTimestamp) [\(localCen.CEN)]")
            
            for key in keys {
                let candidateCen = cenLogic.generateCen(CENKey: key.cenKey, timestamp: roundedLocalTimestamp)
                let candidateCenHex = candidateCen.toHex()
                print("candidateCenHEx: [\(candidateCenHex)] based on key [\(key.cenKey) \(key.timestamp)]")
                if localCen.CEN == candidateCenHex {
                    print("match found for [\(candidateCenHex)]")
                    matchedKeys.append(key)
                }
                
            }
        }
        
        return matchedKeys
    }
    

    // Copied from Android implementation
    private func match(key: CENKey, maxTimestamp: Int64) -> [CEN] {

        // Unclear why maxTimestamp is a parameter
        let maxTimestamp = Date().coEpiTimestamp
        
        
        // take the last 7 days of timestamps and generate all the possible CENs (e.g. 7 days) TODO: Parallelize this?
        let minTimestamp: Int64 = maxTimestamp - 7*24*60*60
        let CENLifetimeInSeconds = 15*60   // every 15 mins a new CEN is generated
        
        let modulus = maxTimestamp % Int64(CENLifetimeInSeconds)
        
        let roundedMaxTimestamp = maxTimestamp - modulus
        
        os_log("Starting CEN calculation for maxTimestamp: %@, CENLifetimeInSeconds: %@, roundedMaxTimestamp: %@", log: servicesLog, type: .debug, "\(maxTimestamp)", "\(CENLifetimeInSeconds)", "\(roundedMaxTimestamp)")

        // last time (unix timestamp) the CENKeys were requested

        let max = Int(Double(7*24*60*60)/Double(CENLifetimeInSeconds))

        var possibleCENs: [String] = []
        possibleCENs.reserveCapacity(max)

        for i in 0...max {
            let ts = maxTimestamp - Int64(CENLifetimeInSeconds * i)
            let cen = cenLogic.generateCen(CENKey: key.cenKey, timestamp: ts)
//            possibleCENs[i] = cen.toHex()
            possibleCENs.append(cen.toHex()) // No fixed size array
        }

        os_log("Generated results for key: %@, possible CENs: %@",
               log: servicesLog, type: .debug, key.cenKey, "\(possibleCENs.count)")

        return cenRepo.match(start: minTimestamp, end: maxTimestamp, hexEncodedCENs: possibleCENs)
    }
    
    
}
