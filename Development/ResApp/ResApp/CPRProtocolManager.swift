import SwiftUI

struct CPRProtocolManager {
    let intervalDuration: TimeInterval = 120 // 2 minutes in seconds
    let totalIntervals = 9
    
    func getAlertForInterval(_ interval: Int, currentECGRhythm: String?) -> String? {
            switch interval {
            case 0:
                return "Check ECG rhythm"
            case 1:
                return "Administer Adrenaline 1 mg IV bolus"
            case 2: 
                return "Administer Amiodarone 300 mg IV bolus"
            case 3:
                return "Administer Adrenaline 1 mg IV bolus"
            case 4:
                return "Administer Amiodarone 150 mg IV bolus"
            case 5:
                return "Administer Adrenaline 1 mg IV bolus"
            case 6, 7, 8:
                return "Continue CPR, reassess rhythm"
            default:
            return nil
        }
    }
    
    func shouldDefibrillate(ecgRhythm: String?) -> Bool {
        return ecgRhythm == "VF" || ecgRhythm == "VT"
    }
}
