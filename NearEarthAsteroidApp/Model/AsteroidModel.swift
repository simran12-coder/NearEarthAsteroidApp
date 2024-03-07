//
//  AsteroidModel.swift
//  NearEarthAsteroidApp
//
//  Created by Simranjeet Kaur on 07/03/24.
//

import SwiftyJSON

class AsteroidsModel {
    
    var element_count: Int?
    let dateformatter = DateFormatter()
    var nearEarthObjects: [String: [NearEarthObjects]?]?
    
    init(fromJSON json: JSON!) {
        if json.isEmpty {
            return
        }
        element_count = json["element_count"].intValue
        
        let nearEarthObjectsDict = json["near_earth_objects"].dictionaryValue
        var nearEarthObjects: [String: [NearEarthObjects]] = [:]
        for (date, objects) in nearEarthObjectsDict {
            let neos = objects.arrayValue.compactMap {
                NearEarthObjects(fromJSON: $0)
            }
            nearEarthObjects[date] = neos
        }
        self.nearEarthObjects = nearEarthObjects
    }
   
}

class NearEarthObjects: Decodable {
    
    var id:String?
    var neo_reference_id:String?
    var name:String?
    var kilometers:KiloMetersModel?
    var closeApproachData: [CloseApproachDataModel] = []
    
    init(fromJSON json: JSON!) {
        if json.isEmpty {
            return
        }
        id = json["id"].stringValue
        neo_reference_id = json["neo_reference_id"].stringValue
        name = json["name"].stringValue
        kilometers = KiloMetersModel(fromJSON: json["kilometers"])
        
        closeApproachData = [CloseApproachDataModel]()
        let closeApproachArray = json["close_approach_data"].arrayValue
        for item in closeApproachArray {
            let closeApproachDataModel = CloseApproachDataModel(fromJSON: item)
            closeApproachData.append(closeApproachDataModel)
        }
    }
}

class CloseApproachDataModel: Decodable {
    
    var close_approach_date_full: String?
    var relative_velocity: RelativeVelocityModel?
    var miss_distance: MissDistanceModel?
   
    init(fromJSON json: JSON!) {
        if json.isEmpty {
            return
        }
        close_approach_date_full = json["close_approach_date_full"].stringValue
        relative_velocity = RelativeVelocityModel(fromJSON: json["relative_velocity"])
        miss_distance = MissDistanceModel(fromJSON: json["miss_distance"])
    }
}

class MissDistanceModel: Decodable {
    var miles: String?
    var kilometers: String?
    
    init(fromJSON json: JSON!) {
        if json.isEmpty {
            return
        }
        miles = json["miles"].stringValue
        kilometers = json["kilometers"].stringValue
    }
}

class RelativeVelocityModel: Decodable {
    var kilometers_per_second: String?
    var kilometers_per_hour: String?
    var miles_per_hour: String?
    
    init(fromJSON json: JSON!) {
        if json.isEmpty {
            return
        }
        kilometers_per_second = json["kilometers_per_second"].stringValue
        kilometers_per_hour = json["kilometers_per_hour"].stringValue
        miles_per_hour = json["kilometers_per_second"].stringValue
    }
}

class KiloMetersModel: Decodable {
    
    var estimated_diameter_min:Int?
    var estimated_diameter_max:Int?
   
    init(fromJSON json: JSON!) {
        if json.isEmpty {
            return
        }
        estimated_diameter_min = json["estimated_diameter_min"].intValue
        estimated_diameter_max = json["estimated_diameter_max"].intValue
    }
}


