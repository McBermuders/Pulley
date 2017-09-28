//
//  DrawerPreviewContentViewController.swift
//  Pulley
//
//  Created by Brendan Lee on 7/6/16.
//  Copyright © 2016 52inc. All rights reserved.
//

import UIKit
import Pulley

class DrawerContentViewController: UIViewController, PullToDismissDelegate,AddOffsetPullDelegate,PullParentDelegate {

    

    func mainScrollView(scrollview: UIScrollView, viewController: PulleyViewController) {
        self.mainScrollView = scrollview
        self.pulleyViewController = viewController
    }
    private var mainScrollView: UIScrollView?
    private var pullToDismiss: PullToDismiss?
    private var pulleyViewController: PulleyViewController?
    
    @IBOutlet var tableView: UITableView!
    @IBOutlet var searchBar: UISearchBar!
    @IBOutlet var gripperView: UIView!
    
    @IBOutlet var separatorHeightConstraint: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        gripperView.layer.cornerRadius = 2.5
        separatorHeightConstraint.constant = 1.0 / UIScreen.main.scale
        pullToDismiss = PullToDismiss(scrollView: tableView, viewController: self)
        pullToDismiss?.delegatePull = self
        pullToDismiss?.mainDelegate = self
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    //MARK: - PullParentDelegate
    func shouldScroll() -> Bool {
        return self.pulleyViewController!.shouldScroll()
    }
    
    //MARK: - PullToDismissDelegate
    var wasDragged: Bool = false
    func addOffset(addOffset: CGFloat){
        print("\(addOffset)")
        wasDragged = true
        let p = CGPoint(x: self.mainScrollView!.contentOffset.x, y: self.mainScrollView!.contentOffset.y-addOffset)
        self.mainScrollView?.setContentOffset(p, animated: false)
        //tableView.isScrollEnabled = false
        //NotificationCenter.default.post(name: Notification.Name.init("jkjkj"), object: NSNumber(value: addOffset))
    }
    
    func finishedDragging(withVelocity velocity: CGPoint){
        if wasDragged{
            wasDragged = false
            //tableView.isScrollEnabled = true
            var p = CGPoint(x: velocity.x, y: velocity.y)
            if velocity.y > 0{
                
            }else{
                
            }
            self.mainScrollView?.delegate?.scrollViewWillEndDragging!(self.mainScrollView!, withVelocity: velocity, targetContentOffset: &p)
            self.mainScrollView?.delegate?.scrollViewDidEndDragging!(self.mainScrollView!, willDecelerate: false)
        }

    }

}

extension DrawerContentViewController: PulleyDrawerViewControllerDelegate {
    
    func collapsedDrawerHeight() -> CGFloat
    {
        return 68.0
    }
    
    func partialRevealDrawerHeight() -> CGFloat
    {
        return 264.0
    }
    
    func supportedDrawerPositions() -> [PulleyPosition] {
        return PulleyPosition.all // You can specify the drawer positions you support. This is the same as: [.open, .partiallyRevealed, .collapsed, .closed]
    }
    
    func drawerPositionDidChange(drawer: PulleyViewController)
    {
        //tableView.isScrollEnabled = drawer.drawerPosition == .open
        
        if drawer.drawerPosition != .open
        {
            searchBar.resignFirstResponder()
        }
    }
}

extension DrawerContentViewController: UISearchBarDelegate {
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        
        if let drawerVC = self.parent as? PulleyViewController
        {
            drawerVC.setDrawerPosition(position: .open, animated: true)
        }
    }
}

extension DrawerContentViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 50
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return tableView.dequeueReusableCell(withIdentifier: "SampleCell", for: indexPath)
    }
}

extension DrawerContentViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 81.0
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if let drawer = self.parent as? PulleyViewController
        {
            let primaryContent = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "PrimaryTransitionTargetViewController")
            
            drawer.setDrawerPosition(position: .collapsed, animated: true)
            
            drawer.setPrimaryContentViewController(controller: primaryContent, animated: false)
        }
    }
}


