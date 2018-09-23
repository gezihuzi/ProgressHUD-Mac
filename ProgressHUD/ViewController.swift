//
//  ViewController.swift
//  ProgressHUD, https://github.com/massimobio/ProgressHUD
//
//  Created by Massimo Biolcati on 9/10/18.
//  Copyright © 2018 Massimo. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {

    @IBOutlet private var locationSegmentedControl: NSSegmentedControl!
    @IBOutlet private var modeSegmentedControl: NSSegmentedControl!
    @IBOutlet private var styleSegmentedControl: NSSegmentedControl!
    @IBOutlet private var maskSegmentedControl: NSSegmentedControl!
    @IBOutlet private var positionSegmentedControl: NSSegmentedControl!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }

    @IBAction func showHUD(_ sender: Any) {

        // set ProgressHUD defaults according to user selected options
        applyUserSelectedHUDStyle()
        applyUserSelectedHUDMaskType()
        applyUserSelectedHUDPosition()
        ProgressHUD.setContainerView(locationSegmentedControl.selectedSegment == 0 ? view : nil)

        switch modeSegmentedControl.selectedSegment {

        case 0: // Indeterminate
            ProgressHUD.show(withStatus: "Indeterminate Progress…")
            ProgressHUD.dismiss(delay: 2)

        case 1: // Determinate
            ProgressHUD.show(withStatus: "Determinate Progress…")
            DispatchQueue.global(qos: .default).async {
                var progress = 0.0
                for _ in 0..<100 {
                    usleep(10000)
                    progress += 0.01
                    DispatchQueue.main.async {
                        ProgressHUD.show(progress: progress, status: "Determinate Progress…")
                    }
                }
                DispatchQueue.main.async {
                    ProgressHUD.dismiss(delay: 1)
                }
            }

        case 2: // info
            ProgressHUD.showInfoWithStatus("Showing text only.\nOn multiple lines.\nSquashed much?")

        case 3: // Success
            ProgressHUD.showSuccessWithStatus("Everything worked out in the end")

        case 4: // Error
            ProgressHUD.showErrorWithStatus("Something bad happened!")

        case 5: // Image
            ProgressHUD.showImage(NSImage(named: "unicorn")!, status: "I'm not a horse")

        default:
            break
        }
    }

    private func applyUserSelectedHUDStyle() {
        switch styleSegmentedControl.selectedSegment {
        case 0: return ProgressHUD.setDefaultStyle(.light)
        case 1: return ProgressHUD.setDefaultStyle(.dark)
        default: return ProgressHUD.setDefaultStyle(.custom(foreground: .yellow, backgroud: .red))
        }
    }

    private func applyUserSelectedHUDMaskType() {
        switch maskSegmentedControl.selectedSegment {
        case 0: return ProgressHUD.setDefaultMaskType(.none)
        case 1: return ProgressHUD.setDefaultMaskType(.clear)
        case 2: return ProgressHUD.setDefaultMaskType(.black)
        default: return ProgressHUD.setDefaultMaskType(.custom(color: NSColor.green.withAlphaComponent(0.6)))
        }
    }

    private func applyUserSelectedHUDPosition() {
        switch positionSegmentedControl.selectedSegment {
        case 0: return ProgressHUD.setDefaultPosition(.top)
        case 1: return ProgressHUD.setDefaultPosition(.center)
        default: return ProgressHUD.setDefaultPosition(.bottom)
        }
    }

}
