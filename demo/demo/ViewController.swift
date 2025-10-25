//
//  ViewController.swift
//  demo
//
//  Created by irons on 2025/1/23.
//

import UIKit

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    // MARK: - Properties
    @IBOutlet weak var tableView: UITableView!

    // MARK: - Lifecycle

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // Uncomment the line below if you want to hide the navigation bar on disappearing
        // navigationController?.setNavigationBarHidden(true, animated: true)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Uncomment the line below if you want to show the navigation bar on appearing
        // navigationController?.setNavigationBarHidden(false, animated: true)
    }

    // MARK: - UITableViewDataSource

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 6
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
        cell.textLabel?.text = "Q"
        return cell
    }

    // MARK: - UITableViewDelegate

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        navigationController?.navigationBar.isHidden = false

        switch indexPath.row {
        case 0:
            let player = IRPlayerUIShellViewController()
            navigationController?.pushViewController(player, animated: true)
        case 1: break
//            let player = IRPlayerViewController()
//            player.displayMode = .quadMode
//            navigationController?.pushViewController(player, animated: true)
        case 2: break
//            navigationController?.navigationBar.isHidden = true
//            let player = IRMultiWindowsPlayerViewController()
//            player.demoType = .ffmpegFisheyeHardwareModesSelection
//            player.displayMode = .quadMode
//            navigationController?.pushViewController(player, animated: true)
        default:
            break
        }
    }

    override var shouldAutorotate: Bool {
        return true
    }
}
