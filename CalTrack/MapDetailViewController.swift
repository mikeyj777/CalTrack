//
//  MapDetailViewController.swift
//  CalTrack
//
//  Created by Faris Sbahi on 5/27/17.
//  Copyright © 2017 Andrew Bihl. All rights reserved.
//

import UIKit

protocol InformingDelegate {
    func valueChanged() -> Stop
}

protocol MapDetailAnimationManager {
    
    /// Respond to the user swiping on the view
    ///
    /// - Returns: Return true if the view was moved/animated as a result of the swipe.
    func userSwipedUp(vc: MapDetailViewController)->Bool;
    
    /// Respond to the user swiping on the view
    ///
    /// - Returns: Return true if the view was moved/animated as a result of the swipe.
    func userSwipedDown(vc: MapDetailViewController)->Bool;
}

class MapDetailViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    var delegate: InformingDelegate?
    
    @IBOutlet var tableView: UITableView!
    @IBOutlet var stopLabel: UILabel!
    
    @IBOutlet var northboundLabel: UILabel!
    @IBOutlet var southboundLabel: UILabel!
    
    public var northDepartures = [Date]()
    public var southDepartures = [Date]()
    
    private var updateTimer : Timer?
    
    var sharedInstance = DataServer.sharedInstance
    
    private var northStop : Stop {
        didSet {
            if (self.isViewLoaded && (self.view.window != nil)) {
            self.stopLabel.text = northStop.stopName.replacingOccurrences(of: "Northbound", with: "")
            }
        }
    }
    private var southStop : Stop
    
    private let BORDER_WIDTH : CGFloat = 1.5
    private let BORDER_COLOR : CGColor = appColor1.cgColor
    
    public var isExpanded = false
    
    required init?(coder aDecoder: NSCoder) {
        northStop = defaultNorthStop
        southStop = defaultSouthStop
        super.init(coder: aDecoder)
    }
    
    init() {
        northStop = defaultNorthStop
        southStop = defaultSouthStop
        super.init(nibName: nil, bundle: nil)
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        tableView.delegate = self
        tableView.dataSource = self
        
        self.northDepartures = self.sharedInstance.getDepartureTimesForStop(stop: northStop)
        self.southDepartures = self.sharedInstance.getDepartureTimesForStop(stop: southStop)
        
        //addObserver(self, forKeyPath: #keyPath(self.sharedInstance.defaultNorthStop), options: [.old, .new], context: nil)
        
    }

    override func viewWillAppear(_ animated: Bool) {
        self.view.backgroundColor = appColor2
        self.view.layer.borderWidth = 3
        self.view.layer.borderColor = BORDER_COLOR
        self.northboundLabel.layer.borderWidth = BORDER_WIDTH
        self.southboundLabel.layer.borderWidth = BORDER_WIDTH
        self.northboundLabel.layer.borderColor = BORDER_COLOR
        self.southboundLabel.layer.borderColor = BORDER_COLOR
    }
    
    override func viewDidAppear(_ animated: Bool) {
        beginUpdateTimer(intervalInSeconds: 60)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.updateTimer?.invalidate()
    }
    
    public func updateStops(northStop: Stop, southStop: Stop) {
        self.northStop = northStop
        self.southStop = southStop
        self.northDepartures = sharedInstance.getDepartureTimesForStop(stop: northStop)
        self.southDepartures = sharedInstance.getDepartureTimesForStop(stop: southStop)
        if (self.isViewLoaded && (self.view.window != nil)) {
        self.stopLabel.text = northStop.stopName.replacingOccurrences(of: "Northbound", with: "")
        }
    }

    
    @IBAction func userSwipedUp(_ sender: UISwipeGestureRecognizer) {
        if let parentVC = self.parent as? MapDetailAnimationManager {
            let changedFrame = parentVC.userSwipedUp(vc: self)
            if changedFrame {
                isExpanded = !isExpanded
            }
        }
    }

    @IBAction func userSwipedDown(_ sender: UISwipeGestureRecognizer) {
        if let parentVC = self.parent as? MapDetailAnimationManager {
            let changedFrame = parentVC.userSwipedDown(vc: self)
            if changedFrame {
                isExpanded = !isExpanded
            }
        }
    }
    
    
    // MARK: - Table View Functions

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell : NorthSouthDeparturesTableViewCell = tableView.dequeueReusableCell(withIdentifier: "NorthSouthCell") as?NorthSouthDeparturesTableViewCell {
            cell.setDepartureTime(time: northDepartures[indexPath.row], north: true)
            cell.setDepartureTime(time: southDepartures[indexPath.row], north: false)
            cell.contentView.layer.borderColor = BORDER_COLOR
            cell.contentView.layer.borderWidth = BORDER_WIDTH
            cell.contentView.backgroundColor = appColor1 //Same as BORDER_COLOR
            return cell
        } else {
            return UITableViewCell()
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if (!isExpanded) {
            return tableView.frame.height
        }
        return tableView.frame.height / CGFloat(self.tableView(tableView, numberOfRowsInSection: indexPath.section))
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return northDepartures.count
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
    }
    
    func beginUpdateTimer(intervalInSeconds: Int){
        updateTimer = Timer(timeInterval: TimeInterval(intervalInSeconds), repeats: true, block: { (timer) in
            print("Updating table.")
            self.tableView.reloadData()
            self.beginUpdateTimer(intervalInSeconds: intervalInSeconds)
        });
        updateTimer?.fire()
    }
    
    
    // MARK: - Key-Value Observing
    /*
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == #keyPath() {
            //
        }
    } */
    
    func closestStopChanged() {
        if let value = self.delegate?.valueChanged() {
        print("closest stop changed", value)
        self.updateStops(northStop: value, southStop: value)
        }
    }
    
}
