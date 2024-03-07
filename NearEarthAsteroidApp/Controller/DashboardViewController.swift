//
//  DashboardViewController.swift
//  NearEarthAsteroidApp
//
//  Created by Simranjeet Kaur on 07/03/24.
//

import UIKit
import Charts
import Alamofire

class DashboardViewController: UIViewController, ChartViewDelegate {
    
    //MARK:- Variables
    var asteroidsObj: AsteroidsModel?
    let datePicker = UIDatePicker()
    let dateFormatter = DateFormatter()
    let toolBar = UIToolbar()
    
    //MARK:- Outlets
    @IBOutlet weak var startDateField: UITextField!
    @IBOutlet weak var endDateField: UITextField!
    @IBOutlet weak var chartView:LineChartView!
    @IBOutlet weak var nearestAsteroid: UILabel!
    @IBOutlet weak var fastestAsteroid: UILabel!
    
    //MARK:- Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpDatePicker()
        chartView.delegate = self
        startDateField.delegate = self
        endDateField.delegate = self
        
    }
    
    //MARK:- For setting up Date picker
    func setUpDatePicker() {
        if #available(iOS 14.0, *) {
            datePicker.preferredDatePickerStyle = .inline
        }
        
        datePicker.frame = CGRect(x: 0, y: 0, width: 0, height: 400)
        dateFormatter.dateFormat = "yyyy-MM-dd"
        datePicker.datePickerMode = .date
        toolBar.sizeToFit()
    }
    
    
    //MARK:- For setting up Line Chart View
    func setUpChartView(xAxisDates: [String]?, yAxisAsteroidsCount: [Int]?) {
        var dataEntries: [ChartDataEntry] = []
        for i in 0..<xAxisDates!.count {
            let dataEntry = ChartDataEntry(x: Double(i), y: Double(yAxisAsteroidsCount![i]))
            dataEntries.append(dataEntry)
        }
        // X-Axis, Y-Axis and Right-Axis Customization
        let set = LineChartDataSet(entries: dataEntries, label: "Date Count") // bottom box text
        // inside circle radius
        set.circleRadius = 5
        // inside circle's innercircle radius
        set.circleHoleRadius = 2
        // to disable enable circle's label
        set.drawValuesEnabled = false
        // to add color under the lines
        set.drawFilledEnabled = true
        // set colors
        set.colors = ChartColorTemplates.joyful()
        
        // add set in chart data-set
        let data = LineChartData(dataSet: set)
        // add set data to chart's data
        chartView.data = data
        
        //MARK:- X-Axis customization
        // to disable-enable text on x-axis
        chartView.xAxis.drawLabelsEnabled = true
        chartView.xAxis.valueFormatter = IndexAxisValueFormatter(values: xAxisDates!)
        // x-axis label count
        chartView.xAxis.setLabelCount(xAxisDates!.count, force: true)
        // Lines attached to X-Axis
        chartView.xAxis.drawGridLinesEnabled = true
        // position text
        chartView.xAxis.labelPosition = .bottom
        // to enable clipping the date text
        chartView.xAxis.avoidFirstLastClippingEnabled = false
        // rotating date text
        chartView.xAxis.labelRotationAngle = -90
        
        //MARK:- Y-Axis customization
        chartView.leftAxis.drawLabelsEnabled = true
        
        //MARK:- Right-Axis customization
        // to disable-enable text on right-axis
        chartView.rightAxis.drawLabelsEnabled = false
    }
    
    //MARK:- Asteroid Neo Api
    func asteroidAPI(completion:@escaping (AsteroidsModel?,Bool?,String)-> Void) {
        if startDateField.text != "" && endDateField.text != "" {
            
            let params:[String:Any] = [
                
                "start_date": startDateField.text!,
                "end_date": endDateField.text!,
                "detailed":true
            ]
            UserDefaults.standard.setValue(startDateField.text!, forKey: "startDate")
            UserDefaults.standard.setValue(endDateField.text!, forKey: "endDate")
            NetworkManager.getRequest(params: params) {(response) in
                guard response.success ?? false else {
                    completion(nil,response.success!, response.message!)
                    return
                }
                let asteroidDetails = AsteroidsModel.init(fromJSON: response.responseJSON!)
                completion(asteroidDetails ,response.success!, response.message!)
            }
        }
        else {
            // Alert Controller when dates are not selected
            let alert = UIAlertController(title: "", message: "Please Add To Date and From Date", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .cancel))
            self.present(alert, animated: true)
        }
        
    }
    
    //MARK:- Action event for Submit button
    @IBAction func submitButtonTapped(_ sender: UIButton) {
        
        self.asteroidAPI { [weak self] (data, status, message) in
            self!.view.isUserInteractionEnabled = false
            guard status! else {
                return
            }
            self!.view.isUserInteractionEnabled = true
            self!.asteroidsObj = data
            self!.getFastestAsteroid()
            self!.getNearestAsteroid()
            
            var dates:[String] = []
            var asteroidsCount:[Int] = []
            if let asteroidsObj = self!.asteroidsObj {
                for (key, value) in asteroidsObj.nearEarthObjects ?? [:] {
                    // appending the dates and asteroid count to show on chartview
                    dates.append(key)
                    asteroidsCount.append(value!.count)
                    self!.setUpChartView(xAxisDates: dates, yAxisAsteroidsCount: asteroidsCount)
                }
            }
        }
    }
    
    //MARK:- Method to get the Fastest Asteroid
    func getFastestAsteroid() {
        if let asteroidsObj = self.asteroidsObj {
            var highestVelocity = 0.0
            var fastestAsteroid = ""
            for (key, value) in asteroidsObj.nearEarthObjects ?? [:] {
                if let asteroids = value {
                    for asteroid in asteroids {
                        print("Day \(key): \(asteroid.closeApproachData.first?.relative_velocity?.kilometers_per_hour ?? "0.0")")
                        // To find the highest velocity asteroid
                        if let velocity = asteroid.closeApproachData.first?.relative_velocity?.kilometers_per_hour {
                            let distance = Double(velocity)
                            if highestVelocity < distance! {
                                highestVelocity = distance!
                                fastestAsteroid = asteroid.name ?? ""
                            }
                        }
                    }
                    self.fastestAsteroid.text = "Fastest Asteroid: \(fastestAsteroid) with the velocity of \(highestVelocity) km/h"
                }
            }
        }
    }
    
    //MARK:- Method to get the Nearest Asteroid
    func getNearestAsteroid() {
        if let asteroidsObj = self.asteroidsObj {
            var nearestAsteroidDistance = 0.0
            var nearestAsteroid = ""
            for (key, value) in asteroidsObj.nearEarthObjects ?? [:] {
                if let asteroids = value {
                    for asteroid in asteroids {
                        print("Day \(key): \(asteroid.closeApproachData.first?.miss_distance?.kilometers ?? "0.0")")
                        // To find the nearest asteroid and it's distance
                        if let velocity = asteroid.closeApproachData.first?.miss_distance?.kilometers {
                            let nearestDist = Double(velocity)
                            if nearestAsteroidDistance > nearestDist! || nearestAsteroidDistance == 0.0 {
                                nearestAsteroidDistance = nearestDist!
                                nearestAsteroid = asteroid.name ?? ""
                            }
                        }
                    }
                }
            }
            self.nearestAsteroid.text = "Nearest Asteroid: \(nearestAsteroid) with the distance of \(nearestAsteroidDistance) kms"
        }
    }
}



extension DashboardViewController: UITextFieldDelegate {
    
    //MARK:- Textfield delegate method
    func textFieldDidBeginEditing(_ textField: UITextField) {
        if textField == startDateField {
            let spaceButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.flexibleSpace, target: nil, action: nil)
            let cancelButtton = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(cancelPickerForStartDate))
            let doneButton = UIBarButtonItem(title: "Done", style: .plain, target: self, action: #selector(datePickerForStartDate))
            toolBar.setItems([spaceButton,doneButton,cancelButtton], animated: true)
            startDateField.inputAccessoryView = toolBar
            startDateField.inputView = datePicker
            startDateField.becomeFirstResponder()
        }
        else if textField == endDateField {
            let spaceButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.flexibleSpace, target: nil, action: nil)
            let cancelButtton = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(cancelPickerForEndDate))
            let doneButton = UIBarButtonItem(title: "Done", style: .plain, target: self, action: #selector(datePickerForEndDate))
            toolBar.setItems([spaceButton,doneButton,cancelButtton], animated: true)
            endDateField.inputAccessoryView = toolBar
            endDateField.inputView = datePicker
            endDateField.becomeFirstResponder()
            
        }
    }
    
    @objc func cancelPickerForStartDate() {
        startDateField.endEditing(true)
    }
    
    @objc func datePickerForStartDate() {
        startDateField.text = dateFormatter.string(from: datePicker.date)
        startDateField.endEditing(true)
    }
    
    @objc func cancelPickerForEndDate() {
        endDateField.endEditing(true)
    }
    
    @objc func datePickerForEndDate() {
        endDateField.text = dateFormatter.string(from: datePicker.date)
        endDateField.endEditing(true)
    }
}





