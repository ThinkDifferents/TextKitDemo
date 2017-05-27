//
//  ViewController.swift
//  Text
//
//  Created by shiwei on 17/5/27.
//  Copyright © 2017年 shiwei. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    @IBOutlet weak var label: SWLabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        label.text = "http://www.baidu.com, 张三,李四,王五,赵六...@李晨,@掌声,,#傻逼一个#"
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

